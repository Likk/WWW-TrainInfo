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
get_delay
get_stop
get_cancel
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
  return $self;
}

=head2 get_info
=head2 get_delay
=head2 get_stop
=head2 get_cancel

those methods are abstract methods.

=cut


for my $method (@$abstruct_methods) {
  my $method_ref = sub { Carp::croak ('this method is abstract') };
  {
    no strict 'refs';
    *{"WWW::TrainInfo::Plugin::Base::${method}"} = $method_ref;
  }
}

1;

=head1 AUTHOR

likkradyus E<lt>perl {at} li {dot} que {dot} jpE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=
