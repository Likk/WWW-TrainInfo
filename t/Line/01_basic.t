use strict;
use warnings;
use Test::More;
use WWW::TrainInfo::Line;
use Time::Piece 1.20 ();

subtest 'basic test' => sub {
  my $t = Time::Piece::localtime();
  my $w = WWW::TrainInfo::Line->new(
    date        =>  $t,
    name        => 'Sounan-Hinjaku line',
    delay_flag  => 1,
    stop_flag   => 0,
    cancel_flag => 0,
    description => 'Fog is causing delays for services at Shounan-Hinjaku line',
    cause       => 'Fog',
  );

  isa_ok($w, 'WWW::TrainInfo::Line', 'isa test');
  is $w->{name}, 'Sounan-Hinjaku line';
  is $w->{delay_flag}, 1;
  ok $w->is_delay;
  isnt $w->is_stop, 1;
  isnt $w->is_cancel, 1;
};

done_testing();
