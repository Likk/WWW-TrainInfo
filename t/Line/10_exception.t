use strict;
use warnings;
use Test::More;
use Test::Exception;
use WWW::TrainInfo::Line;
use Time::Piece 1.20 ();

subtest 'exception test' => sub {
  my $t = Time::Piece::localtime();

  my %opt = ();

  dies_ok  { WWW::TrainInfo::Line->new(%opt); };

  $opt{name} = 'Sounan-Hinjaku line';
  dies_ok  { WWW::TrainInfo::Line->new(%opt); };

  $opt{date} = $t;
  dies_ok  { WWW::TrainInfo::Line->new(%opt); };

  $opt{description} = 'anything';
  lives_ok { WWW::TrainInfo::Line->new(%opt); };

  $opt{other} = 'someone';
  dies_ok  { WWW::TrainInfo::Line->new(%opt); };

};

done_testing();
