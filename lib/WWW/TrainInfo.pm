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

our $VERSION = '0.01';

sub new {
  my $class = shift;
  my %args  = @_;
  my $self  = bless { %args }, $class;
  $self->plugin_load;
  return $self;
}

sub plugin_load {
  my $self = shift;
  my $plugins = $self->{load_plugins};
  for my $plugin (@$plugins) {
    $self->{$plugin} = plugin($plugin);
  }
}

sub get_info {
  my $self = shift;
  my $plugins = $self->{load_plugins};
  for my $plugin (@$plugins) {
    $self->{$plugin}->get_info;
  }

}

sub notice {
  my $self    = shift;
  my $plugins = $self->{load_plugins};
  return map { $self->{$_}->{records} } @$plugins
}

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
