package WWW::TrainInfo::Plugin::JREast;

=head1 NAME

WWW::TrainInfo::Plugin::JREast - JR East train information for WWW::TrainInfo::Plugin.

=head1 SYNOPSIS

  use WWW::TrainInfo::Plugin::JREast;
  my $t = WWW::TrainInfo::Plugin::JREast->new;
  $t->get_info;
  my $records = $t->records;
  warn YAML::Dump $j->records;

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
  for my $row (@$area){
    my $res        = $mech->get("@{[$BASE_URL]}/@{[$AREA_DATA->{$row}->{'sub_url'}]}");
    my $records_wk = $self->_inspect($self->_parse($res->decoded_content), $row);
  }
}

sub _parse {
  my $self = shift;
  my $html = shift;

  my $scraper = scraper {
    process '//table[@id="TblInfo"]',  description => 'TEXT';
    result 'description';
  };
  return $scraper->scrape($html);
}

sub _inspect {
  my $self = shift;
  my $text = shift;
  my $area = shift;

  if($text =~ /^(.*)(\d{4}年\d{1,2}月\d{1,2}日\d{1,2}時\d{1,2}分\s配信)(.*。?)(\s)*/){
  #配信情報がある

      #配信情報を一軒ずつ取り出しながら、中身を加工する
      my @records_wk = map { $self->_record_inspect_callback($_, $area) }
        ($text =~ m{(?:.*?)(?:\d{4}年\d{1,2}月\d{1,2}日\d{1,2}時\d{1,2}分 配信?)(?:.*?。)}g);
      for(@records_wk){
        $self->add_record(%$_);
      }
  }
  else {
      #平常通りのアナウンスが不要ならreturn.
      return if $self->{notify_no_delay} == 0;
      #必要なら、現在の時刻で平常の情報をセット
      my $now = Time::Piece::localtime();
      my $record_wk = {
        name        => 'all-lines',
        date        => $now,
        normal_flag => 1,
        area        => $AREA_DATA->{$area}->{name},
        description => $text,
      };
      $self->add_record(%$record_wk);
  }
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
          $record->{name}   = $line_name;

          #本日発車時(寝台特急用)
          if($line_name =~ m/本日(.*?)発車の/){
            $record->{today_flag} = 1;
          }
        }

        #列車進行方向 片方向向きでのみの遅延/運休/見合わせなどのケース
        if($description =~ m{影響で、(?:一部(?:の)?)?(上下(線|列車)|上り|下り|北行|南行|(内・外|[^・]外|内)回り|(.*)?(方面)?行き)(の|で|に|電車(で|に|の))}){
          $record->{direction} = $1;
        }

        #遅延：         遅れて入るけど動いてはいる。
        #運転見合わせ： 一時的に電車が動いていないが運行している。
        #運休：         特定の、またはダイヤ上の電車全ての運行をしない
        #
        ##TODO:終日運転見合わせというのが増えたらしいぞ。

        #遅延しているか
        if($description =~ m{遅れ(と|がでています)}){
          $record->{delay_flag} = 1;
        }

        #運転見合わせなのか
        if($description =~ m{運転を見合わせ(てい)?ます}){
          $record->{stop_flag} = 1;
        }

        #運休するのか
        if($description =~ m{運休とな(ってい|り)ます。}){
          $record->{cancel_flag} = 1;
        }

        #一部だけか
        if($description =~ m{一部列車が}){
          $record->{not_all_flag} = 1;
        }

        #どうしてそうなったか。
        if($description =~ m{(.*?)、(.*の影響(で|が見込まれるため))}){
          $record->{cause} = $2;
        }

        #一部区間の場合
        if($description =~ m{(?:.*)(?:[。、])((.*)～(.*)(駅間))[はでの]}){
          $record->{section} = $1;
        }

        #直通運転中止
        if($description =~ m{(?:.*)?、(.*)?への直通運転を中止しています。}){
          $record->{not_through_flag} = 1;
          $record->{not_through_name} = $1;
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
