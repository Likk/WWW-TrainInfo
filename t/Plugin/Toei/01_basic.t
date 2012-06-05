use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use WWW::TrainInfo::Plugin::Toei;
use Time::Piece 1.20 ();

sub prepare {
  my $code = sub { return WWW::Mechanize->new( agent => q{Mozilla/5.0 (Windows NT 6.0; rv:12.0) Gecko/20100101 Firefox/12.0 }) };
  {
    no strict 'refs';
    *{"WWW::TrainInfo::Plugin::Toei::mech"} = $code;
  }

}

subtest 'basic test' => sub {
  prepare();

  my $w = WWW::TrainInfo::Plugin::Toei->new( notify_no_delay => 1 );

  isa_ok $w,                'WWW::TrainInfo::Plugin::Toei',   'isa test';
  isa_ok $w->mech,          'WWW::Mechanize',                 'mech loaded';
  is scalar @{$w->records}, 0,                                'no_record';
  lives_ok { $w->get_info; }                                  'can get_info';

  ok scalar @{$w->records},                                   'any_record';
  my $records = $w->records;
  if(scalar(@$records) >= 1){
    for my $l (@$records){
      isa_ok $l, 'WWW::TrainInfo::Line',                                'recode is WWW::TrainInfo::Line';
      if($l->is_delay){
        like $l->description, qr/(?:遅延情報|遅れが発生しています。)/,  'delay ok';
      }
      elsif($l->is_stop){
        die 'no implement';
      }
      elsif($l->is_cancel){
        like $l->description, qr/運休が発生しています/,                 'cancel ok';
      }
      elsif($l->is_normal){
        like $l->description, qr/現在、１５分以上の遅延はありません。/, 'normal ok';
      }
      else{
        TODO: {
          local $TODO = 'imprement me';
          ok 0, 'is not delay, stop, cancel amd normal :'. $l->description;
        }
      }
    }
  }
  else {
    ok 0, 'no record error.';
  }

};

done_testing();
