package WWW::TrainInfo::Plugin::Toei;

=head1 NAME

WWW::TrainInfo::Plugin::Toei - Toei metro information for WWW::TrainInfo::Plugin.

=head1 SYNOPSIS

  use WWW::TrainInfo::Plugin::Toei;
  use YAML;

  my $t = WWW::TrainInfo::Plugin::Toei->new;
  $t->get_info;
  my $records = $t->records;
  warn YAML::Dump $records;

=head1 DESCRIPTION

WWW::TrainInfo::Plugin::TokyoMetoro is train information at "Bureau of Transportation Tokyo Metropolitan Government" for WWW::TrainInfo.
get any delay, stop and cancel train information.

=cut

use strict;
use warnings;
use utf8;
use parent 'WWW::TrainInfo::Plugin::Base';
use Encode;
use Web::Scraper;

our $VERSION = '0.2';
our $INFO_PATH = "http://www.kotsu.metro.tokyo.jp/subway/schedule/index.html";

=head1 CONSTRUCTOR AND STARTUP

=head2 new

Creates and returns a new WWW::TrainInfo::Plugin::Toei object.:

=cut

sub new {
  my $class = shift;
  my $self  = __PACKAGE__->SUPER::new(@_);
  $self->{notify_no_delay} ||= 0;
  return $self;
}

=head1 METHODS

=head2 get_info

read train information.

=cut


sub get_info {
  my $self = shift;
  my $mech = $self->mech;
  my $res  = $mech->get($INFO_PATH);
  $self->_inspect($self->_parse($res->decoded_content));
  return 1;
}

sub _parse {
  my $self = shift;
  my $html = shift;
  my $scraper = scraper {
    process '//div["@id=LayerContents"]/div[@class="InformationUnkou"]/table/tr',
      'data[]' => scraper {
        process '//th',                  name        => 'TEXT';
        process '//td[1]',               description => 'TEXT';
        process '//td[@class="rireki"]', history     => 'TEXT';
      };
      result 'data';
  };

  return $scraper->scrape($html);
}

sub _inspect {
  my $self = shift;
  my $data = shift;

  my @records_wk = map  {
    $self->_record_inspect_callback($_)
  }
  grep { #nameとdescriptionのないrowは無視
    defined $_->{name} and defined $_->{description}
  } @$data;


  for(@records_wk){
    $self->add_record(%$_);
  }
  return 1;
}

sub _record_inspect_callback {
  my $self = shift;
  my $data = shift;

  my $t       = Time::Piece::localtime();
  my $record  = {};

  $record->{date}        = $t;
  my $name               = $data->{name};

  $name                  =~ s{:}{};
  $name                  = '都営'. $name;
  $record->{name}        = $name;
  my $description        = $data->{description};
  $record->{description} = $description;

  #RODO:case文
  if($description eq '現在、１５分以上の遅延はありません。'){
    $record->{normal_flag} = 1;
  }
  if($description =~ m{(?:遅延情報|遅れが発生しています。)}){
    $record->{delay_flag}  = 1;
  }
  {   ###
    1;###運転を見合わせのパターン見たこと無い
  }   ###
  if($description =~ m{運休が発生しています}){
    $record->{cancel_flag} = 1;
  }
  if($description =~ m{一部列車[がにで]}){
    $record->{not_all_flag} = 1;
  }
  if($description =~ m{、(.*の影響により、|.*のため、)}){
    $record->{cause} = $1;
  }

  return $record;
}

1;
