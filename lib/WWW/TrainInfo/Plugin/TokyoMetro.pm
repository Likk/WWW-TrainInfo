package WWW::TrainInfo::Plugin::TokyoMetro;

=head1 NAME

WWW::TrainInfo::Plugin::TokyoMetoro - TokyoMetro information for WWW::TrainInfo::Plugin.

=head1 SYNOPSIS

  use WWW::TrainInfo::Plugin::TokyoMetoro;
  use YAML;

  my $t = WWW::TrainInfo::Plugin::TokyoMetoro->new;
  $t->get_info;
  my $records = $t->records;
  warn YAML::Dump $records;

=head1 DESCRIPTION

WWW::TrainInfo::Plugin::TokyoMetoro is train information of TokyoMetro for WWW::TrainInfo.
get any delay, stop and cancel train information.

=cut

use strict;
use warnings;
use utf8;
use parent 'WWW::TrainInfo::Plugin::Base';
use Encode;
use Web::Scraper;

our $VERSION = '0.1';
our $INFO_PATH = "http://www.tokyometro.jp/unkou/";

=head1 CONSTRUCTOR AND STARTUP

=head2 new

Creates and returns a new WWW::TrainInfo::Plugin::JREast object.:

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
  my $self     = shift;
  my $mech     = $self->mech;
  my $res        = $mech->get($INFO_PATH);
  $self->_inspect($self->_parse($res->decoded_content));
  return 1;
}

sub _parse {
  my $self = shift;
  my $html = shift;

  my $scraper = scraper {
    process '//div[@class="h2SecInner"]/table/tr',
      'data[]' => scraper {
        process '//td[1]/img', name        => '@alt';
        process '//td[2]',     description => 'TEXT';
        process '//td[3]',     history     => 'TEXT';
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
  $name =~ s{:}{};

  $record->{name}        = $name;
  my $description        = $data->{description};
  $record->{description} = $description;

  #TODO:case文
  if($description eq '現在、平常どおり運転しています。'){
    $record->{normal_flag} = 1;
  }
  if($description =~ m{(?:【(.*)?遅延】|遅れが出ています。)}){
    $record->{delay_flag} = 1;
  }
  if($description =~ m{運転を見合わせています}){
    $record->{stop_flag}  = 1;
  }
  if($description =~ m{運休しています}){
    $record->{cancel_flag} = 1;
  }
  if($description =~ m{【ダイヤ乱れ】}){
    $record->{confuse_flag} = 1;
  }
  if($description =~ m{(?:【.*?】)(.*のため、)}){
    $record->{cause} = $1;
  }

  return $record;
}

1;

=head1 AUTHOR

likkradyus E<lt>perl {at} li {dot} que {dot} jpE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
