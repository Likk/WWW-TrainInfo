package WWW::TrainInfo::Util;

=head1 NAME

WWW::TrainInfo::Util - utility for WWW::TrainInfo.

=head1 SYNOPSIS

  use WWW::TrainInfo;
  sub mech {
    my $self = shift;
    $self->{mech} = container(mech)
      if not exists $self->{mech};
    return $self->{mech};
  }

=head1 DESCRIPTION

WWW::TrainInfo::Util is singleton utility for WWW::TrainInfo.

=cut

use strict;
use warnings;
use utf8;
use UNIVERSAL::require;
use WWW::Mechanize;
use Time::HiRes;
use parent 'Class::Singleton';

our @exporter = qw/mech/;

=head1 METHODS

=head2 mech

use or create WWW::Mechanize

=cut

sub mech {
  my $self = shift;
  $self->{mech} = WWW::Mechanize->new( agent => q{Mozilla/5.0 (Windows NT 6.0; rv:12.0) Gecko/20100101 Firefox/12.0 }. Time::HiRes::time ) unless ($self->{mech});
  return $self->{mech};

}

=head2 export

export at this module methods for any plugin.

=cut

sub export {
  return \@exporter;
}

=head1 AUTHOR

likkradyus E<lt>perl {at} li {dot} que {dot} jpE<gt>

=head1 SEE ALSO

WWW::TrainInfo

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
