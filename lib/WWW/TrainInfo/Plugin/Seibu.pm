package WWW::TrainInfo::Plugin::Seibu;

=head1 NAME

WWW::TrainInfo::Plugin::Seibu - Seibu metro information for WWW::TrainInfo::Plugin.

=head1 SYNOPSIS

  use WWW::TrainInfo::Plugin::Seibu;
  use YAML;

  my $t = WWW::TrainInfo::Plugin::Seibu->new;
  $t->get_info;
  my $records = $t->records;
  warn YAML::Dump $records;

=head1 DESCRIPTION

WWW::TrainInfo::Plugin::TokyoMetoro is train information at Seibu-Railway for WWW::TrainInfo.
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
our $INFO_PATH = "http://www.seibu-group.co.jp/railways/unten/unten.asp";

=head1 CONSTRUCTOR AND STARTUP

=head2 new

Creates and returns a new WWW::TrainInfo::Plugin::Seibu object.:

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
    process '//div["@class=cmbmod014"]',
      'data[]' => scraper {
        process '//p',               description => 'TEXT';
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

  if($description =~ m{^(\d{4}/\d{2}/\d{2}\s\d{2}:\d{2}:\d{2})}){
    $record->{date} = Time::Piece->strptime($1, '%Y/%m/%d %H:%M:%S');
    $description =~ s{^(?:\d{4}/\d{2}/\d{2}\s\d{2}:\d{2}:\d{2})}{};
    if($description =~ m{^(.*?線)は}){
      $record->{name}        = '西武'. $1;
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

    if($description =~ m{、(.*の影響により)}){
      $record->{cause} = $1;
    }
    if($description =~ m{西武鉄道各線は平常通り運行しております。$}){
      $record->{normal_flag} = 1;
      $record->{name}        = '西武鉄道各線';
    }
  }
  elsif($description =~ m{西武鉄道各線は平常通り運行しております。$}){
    my $t = Time::Piece::localtime();
    $record->{date}        = $t;
    $record->{normal_flag} = 1;
    $record->{name}        = '西武鉄道各線';
  }
  else{
    Carp::carp($description);
  }
  return $record;
}

1;
