package WWW::TrainInfo;

=head1 NAME

WWW::TrainInfo - train information for perl client library.

=head1 SYNOPSIS

  use WWW::TrainInfo;
  my $trainfo = WWW::TrainInfo->new(
    load_plugins => qw(JREast TokyoMetoro),
  );
  $trainfo->get_info();

  my $lines = $trainfo->notice_delay();
  for my $line (@$lines) {
    warn $line->name;
  }

##TODO: not implement
  my $lines = $trainfo->notice;
  for my $line (@$lines) {
    my $notice = $lines->is_delay ? 
      $line->name . ' is delay. ' :
      $lines->is_stop ?
        $line->name . ' is stop. ':
        $lines->is_canel ?
          $line->name . ' is cancel;. ':
          $line->name . ' has any trouble';
    warn $notice;
  }
##

=head1 DESCRIPTION

WWW::TrainInfo is train information for perl client library.

=cut

use strict;
use warnings;
use utf8;
use Encode;
use WWW::TrainInfo::Plugin;

=head1  Package::Global::Variable

=over

=item B<VERSION>

this package version.

=cut

our $VERSION   = '0.01';

=back

=head1 CONSTRUCTOR AND STARTUP

=head2 new

Creates and returns a new WWW::TrainInfo object.:

=cut

sub new {
  my $class = shift;
  my %args  = @_;
  my $self  = bless { %args }, $class;
  $self->_plugin_load;
  return $self;
}

=head1 ACCESSOR

=head1 is_got

accessor for is_got at local variable.

=cut

sub is_got {
  my $self = shift;
  if(defined $_[0] and
     $_[0] =~ m{^(0|1)}){
     $self->{is_got} = $_[0];
  }
  return $self->{is_got};
}

=head1 METHODS

=head2 get_info

get train information from plugin.

=cut

sub get_info {
  my $self = shift;
  my $plugins = $self->{load_plugins};
  for my $plugin (@$plugins) {
    $self->{$plugin}->get_info;
  }

}

=head2 notice

show notice information at all plugin.

=cut

sub notice {
  my $self    = shift;
  Carp::croak('this method is useble after get_info method.') unless $self->is_got;
  my $plugins = $self->{load_plugins};
  return map { $self->{$_}->{records} } @$plugins
}

=head2 delay
=head2 stop
=head2 cancel

those methods are show-able some information.

=cut

=begin comment

create delay,stop and cancel method.

=end comment

=cut

for my $state (qw/delay stop cancel/) {
  my $coderef = sub {
    my $self    = shift;
    my $plugins = $self->{load_plugins};
    my $records = [];
    for my $plugin (@$plugins) {
      my $method = "get_${state}";
      my $records_wk = $self->{$plugin}->$method;
      push @$records, @$records_wk;
    }
    return $records;
  };
  {
    no strict 'refs';
    *{"WWW::TrainInfo::notice_${state}"} = $coderef;
  }
}


=head1 PRIVATE METHODS

=over

=item B<_plugin_load>

=cut

sub _plugin_load {
  my $self = shift;
  my $plugins = $self->{load_plugins};
  for my $plugin (@$plugins) {
    $self->{$plugin} = plugin($plugin);
  }
}

=back

=cut

q{
      ====        ________                ___________
  _D _|  |_______/        \__I_I_____===__|_________|
   |(_)---  |   H\________/ |   |        =|___ ___|
   /     |  |   H  |  |     |   |         ||_| |_||
  |      |  |   H  |__--------------------| [___] |
  | ________|___H__/__|_____/[][]~\_______|       |
  |/ |   |-----------I_____I [][] []  D   |=======|__
__/ =| o |=-~~\  /~~\  /~~\  /~~\ ____Y___________|__
 |/-=|___||    ||    ||    ||    |_____/~\___/
  \_/      \__/  \__/  \__/  \__/      \_/
};

=head1 AUTHOR

likkradyus E<lt>perl {at} li {dot} que {dot} jpE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
