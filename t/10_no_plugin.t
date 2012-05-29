use strict;
use warnings;
use Test::More;
use WWW::TrainInfo;

subtest "no_plugin" => sub {

  my $w = WWW::TrainInfo->new;
  isa_ok $w->{plugins}, 'HASH',       'plugins isa is hash';
  is scalar keys %{$w->{plugins}}, 0, 'it is not set any plugins at default';
  is $w->is_got, 0,                   'is not got';
  ok $w->get_info(),                  'can ok get_info';
  is $w->is_got, 1,                   'is got';

  for my $status (qw/delay stop cancel/){
    my $method = "notice_${status}";
    my $r      = $w->$method();
    isa_ok $r, 'ARRAY',    $method. ' is returning array object';
    is scalar @$r, 0,      $method. ' scalar is 0';
  }
};

done_testing();
