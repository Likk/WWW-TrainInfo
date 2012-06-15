package WWW::TrainInfo::Plugin::Keikyu;

=head1 NAME

WWW::TrainInfo::Plugin::Keikyu - Keikyu information for WWW::TrainInfo::Plugin.

=head1 SYNOPSIS

  use WWW::TrainInfo::Plugin::Keikyu;
  use YAML;

  my $t = WWW::TrainInfo::Plugin::Keikyu->new;
  $t->get_info;
  my $records = $t->records;
  warn YAML::Dump $records;

=head1 DESCRIPTION

WWW::TrainInfo::Plugin::TokyoMetoro is train information at Keikyu for WWW::TrainInfo.
get any delay, stop and cancel train information.

=cut

use strict;
use warnings;
use utf8;
use parent 'WWW::TrainInfo::Plugin::Base';
use Encode;
use Web::Scraper;
use Text::Trim;

our $VERSION = '0.1';
our $INFO_PATH = "http://www.keikyu.co.jp/train/operation_info.shtml";

=head1 CONSTRUCTOR AND STARTUP

=head2 new

Creates and returns a new WWW::TrainInfo::Plugin::Keikyu object.:

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
    process '//div["@id=CONTENTS"]/div[@id="NEWS_DETAIL"]',
      'data[]' => scraper {
        process '//p/big',               description => 'TEXT';
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
  $record->{date} = $t;

  if($description =~ m{^【運行情報】}){
    $description =~ s{^【運行情報】}{};
    $record->{name}        = '京急線';

    #TODO:case文
    if($description =~ m{(?:遅れがでています。)}){
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

    if($description =~ m{、(.*影響で)、}){
      $record->{cause} = $1;
    }
    if($description =~ m{平常通り運転しています。$}){
      $record->{normal_flag} = 1;
      $record->{name}        = '京急線';
    }
  }
  elsif($description =~ m{平常通り運転しています。$}){
    $record->{date}        = $t;
    $record->{normal_flag} = 1;
    $record->{name}        = '京急線';
  }
  else{
    Carp::carp($description);
  }
  return $record;
}

1;
