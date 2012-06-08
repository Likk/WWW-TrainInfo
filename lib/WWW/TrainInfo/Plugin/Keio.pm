package WWW::TrainInfo::Plugin::Keio;

=head1 NAME

WWW::TrainInfo::Plugin::Keio - Keio metro information for WWW::TrainInfo::Plugin.

=head1 SYNOPSIS

  use WWW::TrainInfo::Plugin::Keio;
  use YAML;

  my $t = WWW::TrainInfo::Plugin::Keio->new;
  $t->get_info;
  my $records = $t->records;
  warn YAML::Dump $records;

=head1 DESCRIPTION

WWW::TrainInfo::Plugin::TokyoMetoro is train information at Keio for WWW::TrainInfo.
get any delay, stop and cancel train information.

=cut

use strict;
use warnings;
use utf8;
use parent 'WWW::TrainInfo::Plugin::Base';
use Encode;
use Web::Scraper;
use Text::Trim;

our $VERSION = '0.2';
our $INFO_PATH = "http://www.keio.co.jp/unkou/unkou_pc.html";

=head1 CONSTRUCTOR AND STARTUP

=head2 new

Creates and returns a new WWW::TrainInfo::Plugin::Keio object.:

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
    process '//div["@id=layoutContainer"]/div[@id="layoutContent"]/div[@id="layoutMain"]',
      'data[]' => scraper {
        process '//p[@class="status"]',               description => 'TEXT';
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
  grep { #descriptionのないrowは無視
    defined $_->{description}
  } @$data;


  for(@records_wk){
    $self->add_record(%$_);
  }
  return 1;
}

sub _record_inspect_callback {
  my $self = shift;
  my $data = shift;
  my $description    = Text::Trim::trim($data->{description});
  my $record  = {};
  $record->{description} = $description;
  my $t = Time::Piece::localtime();
  if($description =~ m{^(?:(\d{2})時(\d{2})分頃、)}){
    $t->{hour}   = $1;
    $t->{minute} = $2;
    $description =~ s{^(\d{2}時\d{2}分頃、)}{};
    if($description =~ m{^.*?の為、(.*線)は}){
      $record->{name}        = '京王'. $1;
    }

    #TODO:case文
    if($description =~ m{(?:遅れが出ています。)}){
      $record->{delay_flag}  = 1;
    }

    if(0){
      #TODO:運転を見合わせのパターン
    }
    if(0){
      #TODO:運休のパターン
    }
    if(0){
       #TODO:一部列車とか
    }

    if($description =~ m{、(.*の為)、}){
      $record->{cause} = $1;
    }
    if($description =~ m{平常通り運転しています。$}){
      $record->{normal_flag} = 1;
      $record->{name}        = '京王電鉄各線';
    }
  }
  elsif($description =~ m{平常通り運転しています。$}){
    $record->{date}        = $t;
    $record->{normal_flag} = 1;
    $record->{name}        = '京王電鉄各線';
  }
  else{
    Carp::carp($description);
  }
  return $record;
}

1;
