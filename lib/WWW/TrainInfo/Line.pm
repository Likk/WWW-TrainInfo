package WWW::TrainInfo::Line;

=head1 NAME

WWW::TrainInfo::Line - line information object for WWW::TrainInfo.

=head1 SYNOPSIS

  WWW::TrainInfo::Line;
  my $line = WWW::TrainInfo::Line->new(
    date        => Time::Piece::localtime(),
    name        => 'Sounan-Hinjaku line',
    delay_flg   => 1,
    stop_flg    => 0,
    cancel_flg  => 0,
    description => 'Fog is causing delays for services at Shounan-Hinjaku line',
    cause       => 'Fog',

  );

  my $notice = $line->is_delay ?
    $line->name . ' is delay. ' :
    $line->is_stop ?
       $line->name . ' is stop. ':
       $line->is_canel ?
         $line->name . ' is cancel;. ':
         $line->name . ' has any trouble';
   warn $notice;

=head1 DESCRIPTION

WWW::TrainInfo is line information for WWW::TrainInfo.

=cut

use strict;
use warnings;
use utf8;
use Encode;
use Params::Validate qw(:all);

=head1  Package::Global::Variable:

=over

=item B<VERSION>

this package version.

=cut

our $VERSION   = '0.01';

=back

=head1 CONSTRUCTOR AND STARTUP

=head2 new

Creates and returns a new WWW::TrainInfo::Line object.:

=cut

sub new {
  my $class = shift;
  my $args  = {
    validate(@_ ,
      {
        date         => { isa   => 'Time::Piece' },
        name         => { type  => SCALAR },
        description  => { type  => SCALAR },
        area         => { type  => SCALAR,      optional => 1}, #エリア
        delay_flag   => { regex => qr/^(0|1)$/, optional => 1}, #遅延
        stop_flag    => { regex => qr/^(0|1)$/, optional => 1}, #見合わせ
        cancel_flag  => { regex => qr/^(0|1)$/, optional => 1}, #運休
        confuse_flag => { regex => qr/^(0|1)$/, optional => 1}, #ダイヤ乱れ
        normal_flag  => { regex => qr/^(0|1)$/, optional => 1}, #通常
        cause        => { type  => SCALAR,      optional => 1}, #理由
        today_flag   => { regex => qr/^(0|1)$/, optional => 1}, #本日発車
        not_all_flag => { regex => qr/^(0|1)$/, optional => 1}, #一部列車
        section      => { type  => SCALAR,      optional => 1}, #一部区間
        direction    => { type  => SCALAR,      optional => 1}, #進行方向
      },
    )
  };
  bless { %$args }, $class;
}

=head1 METHODS

=head2 is_delay
=head2 is_stop
=head2 is_cancel

is this line has delay, stop, cancel or confuse news?

=cut

sub is_delay   { shift->{delay_flag}   ? 1 : 0 }
sub is_stop    { shift->{stop_flag}    ? 1 : 0 }
sub is_cancel  { shift->{cancel_flag}  ? 1 : 0 }
sub is_confuse { shift->{confuse_flag} ? 1 : 0 }

=head2 is_normal

this line is normal. (is not delay, stop and cancel.)

=cut

sub is_normal {
  my $self = shift;
  return (
    not $self->is_delay  and
    not $self->is_stop   and
    not $self->is_cancel and
    defined $self->{normal_flag} and
    $self->{normal_flag} == 1
  ) ?
    1:
    0;
}

=head1 ACCESSOR

=over

=item B<name>
=item B<description>
=item B<area>
=item B<cause>
=item B<section>
=item B<direction>

=back

=cut

sub name        { $_[1] ? $_[0]->{name}        = $_[1] : $_[0]->{name}        }
sub description { $_[1] ? $_[0]->{description} = $_[1] : $_[0]->{description} }
sub area        { $_[1] ? $_[0]->{area}        = $_[1] : $_[0]->{area}        || '' }
sub cause       { $_[1] ? $_[0]->{cause}       = $_[1] : $_[0]->{cause}       || '' }
sub section     { $_[1] ? $_[0]->{section}     = $_[1] : $_[0]->{section}     || '' }
sub direction   { $_[1] ? $_[0]->{direction}   = $_[1] : $_[0]->{direction}   || '' }

=head1 AUTHOR

Likkradyus E<lt>perl {at} li {dot} que {dot} jpE<gt>

=head1 SEE ALSO

WWW::TrainInfo

=cut
