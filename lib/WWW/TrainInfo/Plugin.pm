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
use Class::Load;

use WWW::TrainInfo::Util;

our $container = WWW::TrainInfo::Util->instance;

=head1 METHODS

=head2 import

import some plugins.

=cut

sub import {
  my ($class, @opts) = @_;
  my $caller  = caller();

  my $plugin_loader = sub {
    my $name = shift;
    my $module = "WWW::TrainInfo::Plugin\::$name";
    Class::Load::load_class($module) or die;
    _contaier_methods($module);
    my $pkg = $module->new();
    return $pkg;
  };

  {
    no strict 'refs'; ## no critic
    no warnings 'redefine'; ## no critic
    *{"${caller}::plugin"} = $plugin_loader;
  }

}


sub _contaier_methods {
  my $module = shift;
  for my $method_name (@{$container->export}){
    my $method = $container->$method_name;
    my $pm = $module. "::". $method_name;
    {
      no strict 'refs';       ## no critic
      no warnings 'redefine'; ## no critic
      *{ $pm } = sub { $method };
    }
  }
}

=head1 AUTHOR

Likkradyus E<lt>perl {at} li {dot} que {dot} jpE<gt>

=head1 SEE ALSO

WWW::TrainInfo

=cut

1;
