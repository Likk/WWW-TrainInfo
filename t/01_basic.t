use strict;
use warnings;
use Test::More;
use WWW::TrainInfo;

plan (tests => 2);

my $w = WWW::TrainInfo->new;
isa_ok($w, 'WWW::TrainInfo', 'isa test');
can_ok($w, qw/get_info notice notice_delay notice_stop notice_cancel is_got/);

