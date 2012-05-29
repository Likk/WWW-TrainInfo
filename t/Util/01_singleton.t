use strict;
use warnings;
use Test::More;
use WWW::TrainInfo::Util;

subtest "singleton object testing" => sub {

  my $u1 = WWW::TrainInfo::Util->instance;
  my $u2 = WWW::TrainInfo::Util->instance;
  isa_ok $u1->mech,        'WWW::Mechanize';
  is $u1, $u2,             'object equality';
  is $u1->mech, $u2->mech, 'method equality';

  isa_ok $u1->now, 'Time::Piece';
};

done_testing();
