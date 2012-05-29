package WWW::TrainInfo::Plugin::JREast;

=head1 NAME

WWW::TrainInfo::Plugin::JREast - JR East train information for WWW::TrainInfo::Plugin.

=head1 SYNOPSIS

  use WWW::TrainInfo::Plugin::JREast;
  use YAML;
  my $j = WWW::TrainInfo::Plugin::JREast->new;
  $j->get_info;
  warn YAML::Dump $j->get_delay;

=head1 DESCRIPTION

WWW::TrainInfo::Plugin::JREast is train information of JR East for WWW::TrainInfo.
get any delay, stop and cancel train information.

=cut

use strict;
use warnings;
use utf8;
use parent 'WWW::TrainInfo::Plugin::Base';
use Web::Scraper;
use Encode;

our $VERSION = '0.1';
our $SITE_URL = "http://www.jreast.co.jp/";
our $BASE_URL = "http://traininfo.jreast.co.jp/train_info";
our $AREA_DATA = {
  'k' => {
    'name' => '関東エリア',
    'sub_url' => 'kanto.aspx'
  },
  't' => {
    'name' => '東北エリア',
    'sub_url' => 'tohoku.aspx'
   },
  's' => {
    'name' => '信越エリア',
    'sub_url' => 'shinetsu.aspx'
  },
  'S' => {
    'name' => '新幹線',
    'sub_url' => 'shinkansen.aspx'
  },
  'L' => {
    'name' => '長距離列車',
    'sub_url' => 'chyokyori.aspx'
  },
};

=head1 CONSTRUCTOR AND STARTUP

=head2 new

Creates and returns a new WWW::TrainInfo::Plugin::JREast object.:

=cut

sub new {
  my $class = shift;
  my $self  = __PACKAGE__->SUPER::new(@_);
  $self->{area}            ||= [qw(k s t S L)];
  $self->{notify_no_delay} ||= 0;
  $self->{test_news}       ||= 0;
  return $self;
}

=head1 METHODS

=head2 get_info

read train information.

=cut

sub get_info {
  my $self    = shift;
  my $area   = $self->{area};
  my $mech   = $self->{mech};
  warn $mech->agent;
  my $records = [];
  for my $row (@$area){
    my $res        = $mech->get("@{[$BASE_URL]}/@{[$AREA_DATA->{$row}->{'sub_url'}]}");
    my $records_wk = $self->_inspect($self->_parse($res->decoded_content), $row);
    if(ref    $records_wk eq 'ARRAY' and
       scalar $records_wk > 0){
      push @$records, @$records_wk;
    }
  }
  $self->{records} = $records;
}

=head2 get_delay

show delay information.

=cut

sub get_delay {
  my $self       = shift;
  my $records    = $self->{records};
  my $delay_data = [];
  for my $record (@$records){
    if ($record->{delay_flg}){
      push @$delay_data,$record;
    }
  }
  return $delay_data;
}

=head2 get_stop

show stop information.

=cut

sub get_stop {
  my $self      = shift;
  my $records   = $self->{records};
  my $stop_data = [];

  for my $record (@$records){
    if ($record->{stop_flg}){
      push @$stop_data,$record;
    }
  }
  return $stop_data;
}

=head2 get_cancel

show cancel information.

=cut

sub get_cancel {
  my $self        = shift;
  my $records     = $self->{parsed_records};
  my $cancel_data = [];

  for my $record (@$records){
    if ($record->{cancel_flg}){
      push @$cancel_data,$record;
    }
  }
  return $cancel_data;
}


sub _parse {
  my $self = shift;
  my $html = shift;

  my $scraper = scraper {
    process "table#TblInfo",  description => 'TEXT';
    result 'description';
  };
  return $scraper->scrape($html);
}

sub _inspect {
  my $self = shift;
  my $text = shift;
  my $area = shift;
  my $records = [];

  if($text =~ /^(.*)(\d{4}年\d{1,2}月\d{1,2}日\d{1,2}時\d{1,2}分\s配信)(.*。?)(\s)*/){
  #配信情報がある

      #配信情報を一軒ずつ取り出しながら、中身を加工する
      my @records_wk = map { $self->_record_inspect_callback($_, $area) }
        ($text =~ m{(?:.*?)(?:\d{4}年\d{1,2}月\d{1,2}日\d{1,2}時\d{1,2}分 配信?)(?:.*?。)}g);
      push @$records, @records_wk;
  }
  else {
      #平常通りのアナウンスが不要ならreturn.
      return if $self->{notify_no_delay} == 0;
      #必要なら、現在の時刻で平常の情報をセット
      my $record_wk = {
        date        => Time::Piece::localtime(),
        nomal_flg   => 1,
        area        => $AREA_DATA->{$area}->{name},
        description => $text,
      };
      push @$records,$record_wk;

  }
  $records;
}

sub _record_inspect_callback {
  my $self = shift;
  my $text = shift;
  my $area = shift;
  my $record = {};
  if($text =~ m{(.*?)(\d{4}年\d{1,2}月\d{1,2}日\d{1,2}時\d{1,2}分 配信?)(.*?。)}){

        #配信情報文章
        my $description = $3;
        $record->{description} = $description;
        $record->{area}        = $area;
        #配信時間時間
        if($2 =~ m{(\d{4})年(\d{1,2})月(\d{1,2})日(\d{1,2})時(\d{1,2})分}){
          my $ymdhms = sprintf("%d-%02d-%02d %02d:%02d:00", (
              $1,
              $2,
              $3,
              $4,
              $5
            )
          );
          $record->{date} = Time::Piece->strptime($ymdhms, '%Y-%m-%d %H:%M:%S');
        }

        #路線名・名称
        if($description =~ m/^\s*(.*?(.*線.*|ライン|車|.*」))+は、/){
          my $line_name = $1;
          $record->{line_name}   = $line_name;

          #本日発車時(寝台特急用)
          if($line_name =~ m/本日(.*?)発車の/){
            $record->{today_flg} = 1;
          }
        }

        #列車進行方向 片方向向きでのみの遅延/運休/見合わせなどのケース
        if($description =~ m{影響で、(?:一部(?:の)?)?(上下(線|列車)|上り|下り|北行|南行|(内・外|[^・]外|内)回り|(.*)?(方面)?行き)(の|で|に|電車(で|に|の))}){
          $record->{description} = $1;
        }

        #遅延：         遅れて入るけど動いてはいる。
        #運転見合わせ： 一時的に電車が動いていないが運行している。
        #運休：         特定の、またはダイヤ上の電車全ての運行をしない
        #
        ##TODO:終日運転見合わせというのが増えたらしいぞ。

        #遅延しているか
        if($description =~ m{遅れ(と|がでています)}){
          $record->{delay_flg} = 1;
        }

        #運転見合わせなのか
        if($description =~ m{運転を見合わせ(てい)?ます}){
          $record->{stop_flg} = 1;
        }

        #運休するのか
        if($description =~ m{運休とな(ってい|り)ます。}){
          $record->{cancellation} = 1;
        }

        #一部だけか
        if($description =~ m{一部列車が}){
          $record->{not_all_flg} = 1;
        }

        #どうしてそうなったか。
        if($description =~ m{(.*?)、(.*の影響(で|が見込まれるため))}){
          $record->{cause} = $2;
        }

        #一部区間の場合
        if($description =~ m{(?:.*)(?:[。、])((.*)～(.*)(駅間))[はでの]}){
          $record->{section} = $1;
        }
  }
  return $record;
}


1;

=head1 AUTHOR

likkradyus E<lt>perl {at} li {dot} que {dot} jpE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
