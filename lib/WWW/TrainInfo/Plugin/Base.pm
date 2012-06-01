package WWW::TrainInfo::Plugin::Base;

=head1 NAME

WWW::TrainInfo::Plugin::Base - Basic module for plugins at WWW::TrainInfo.

=head1 SYNOPSIS

  package WWW::TrainInfo::Plugin::NewLine
  use parent WWW::TrainInfo::Plugin::Base;

  sub get_info {
    #over wridde abstruct method.
  }

=head1 DESCRIPTION

WWW::TrainInfo::Plugin::Base is Basic module for plugins at WWW::TrainInfo.

=cut

use strict;
use warnings;
use Time::Piece 1.20 ();
use Web::Scraper;
use WWW::TrainInfo::Util;
use WWW::TrainInfo::Line;

our $VERSION = '0.1';
our $abstruct_methods = [qw/
get_info
_parce
_inspect
_record_inspect_callback
/];

=head1 CONSTRUCTOR AND STARTUP

=head2 new

Creates and returns a new WWW::TrainInfo::Base object.:

=cut

sub new {
  my $class  = shift;
  my %h      = @_;
  my $self   = bless { %h },$class;
  my ($pkg,) = caller(0);
  $self->{mech} = $pkg->mech;
  $self->{records} = [];
  return $self;
}

=head2 get_info

this method is abstract methods.

=cut

for my $method (@$abstruct_methods) {
  my $method_ref = sub { Carp::croak ('this method is abstract') };
  {
    no strict 'refs';
    *{"WWW::TrainInfo::Plugin::Base::${method}"} = $method_ref;
  }
}


=head2 get_delay
=head2 get_stop
=head2 get_cancel

show delay, stop, cancel information.

=cut

for my $name (qw/delay stop cancel/){
  my $method_ref = sub {
    my $self        = shift;
    my $records     = $self->records;
    my $delay_data  = [];
    my $method_name = "is_${name}";
    for my $record (@$records){
      if ($record->$method_name){
        push @$delay_data,$record;
      }
    }
    return $delay_data;
  };
  {
    no strict 'refs';
    *{"WWW::TrainInfo::Plugin::Base::get_${name}"} = $method_ref;
  }
}

=head2 records

it is getter for records.

=cut

sub records { shift->{records} || [] }

=head2 add_record

add line information to records.

=cut

sub add_record {
  my $self = shift;
  my %args = @_;
  my $records = $self->records;
  my $line = WWW::TrainInfo::Line->new( %args );
  push @$records, $line;
  $self->{records} = $records;
}

1;

=head1 AUTHOR

likkradyus E<lt>perl {at} li {dot} que {dot} jpE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
