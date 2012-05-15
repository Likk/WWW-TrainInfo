package WWW::TrainInfo::Plugin;

=head1 WWW::TrainInfo::Plugin - plugin loader

=head1 SYNOPSIS

  use WWW::TrainInfo;
  plugin('JREast');
  This code is equivalent to:
     WWW::TrainInfo::Plugin::JREast.pm;

=head1 DESCRIPTION

WWW::TrainInfo::Plugin is a plugin loader for WWW::TrainInfo

=cut

use strict;
use warnings;
use UNIVERSAL::require;

sub import {
  my ($class, @opts) = @_;
  my $caller  = caller();

  my $plugin_loader = sub {
    my $name = shift;
    my $module = "WWW::TrainInfo::Plugin\::$name";
    $module->require or die $@;
    return $module->new();
  };

  {
    no strict 'refs'; ## no critic
    no warnings 'redefine'; ## no critic
    *{"${caller}::plugin"} = $plugin_loader;
  }

}

=head1 AUTHOR

Likkradyus E<lt>perl {at} li {dot} que {dot} jpE<gt>

=head1 SEE ALSO

WWW::TrainInfo

=cut

1;
