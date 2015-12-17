#!/usr/bin/ruby
# coding: utf-8
require 'sqlite3'
require 'cgi'
require 'kconv'
print "Content-type: text/html\n\n"
d = Time.now

def to_min(time)
  if time == "00:00"
    return 0
  else
    arytime = time.split(':')
    return arytime[0].to_i * 60 + arytime[1].to_i
  end
end

def to_h(min)
  hour = min.to_i / 60
  min = min.to_i % 60
  hour = '0' + hour.to_s if hour < 10
  min = '0' + min.to_s if min < 10
  hour.to_s + ':' + min.to_s
end

def chday(day)
  day = '0' + day.to_s if day.to_s.length == 1
  day
end
today = d.year.to_s + '-' + chday(d.month).to_s + '-' + chday(d.day).to_s

def chint(s_data)
  idata = s_data.split('-')
  idata[0].to_s + idata[1].to_s + idata[2].to_s
end

def count(f_name)
  txt = open('../'+f_name, 'r:utf-8')
  t_count = txt.read.count("\n")
  t_count.to_i
end

def print_t(f_name)
  txt = File.open("../"+f_name, 'r:utf-8').readlines
  for i in 0..count(f_name) - 1
    print txt[i].to_s
  end
end

def nextday(today)
  day = today.split('-')
  if day[0] % 4 == 0 && day[0] % 100 == 0 && day[0] % 400 == 0
    # うるうどし
    month = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  else
    month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  end
  mm = day[1].to_i
  if day[1]=="12" && day[2]=="31"
    return (day[0].to_i+1).to_s + "-01-01"
  elsif day[2].to_i < month[mm - 1].to_i
    dd = day[2].to_i + 1
    return day[0].to_s + '-' + chday(day[1]).to_s + '-' + chday(dd).to_s
  else
    mm = day[1].to_i + 1
    return day[0].to_s + '-' + chday(mm).to_s + '-01'
  end
end

def prevday(today)
  day = today.split('-')
  if day[0] % 4 == 0 && day[0] % 100 == 0 && day[0] % 400 == 0
    # うるうどし
    month = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  else
    month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
  end
  mm = day[1].to_i
  if day[1]=="01" && day[2]=="01"
    return day[0].to_i-1+"-12-31"
  elsif day[2]=="01"
    mm=day[1].to_i
    dd=month[mm-2].to_i
    mm=mm.to_i-1
    return day[0].to_s + '-' + chday(mm).to_s + '-' + chday(dd).to_s
  else
    dd=day[2].to_i-1
    return day[0].to_s + '-' + day[1].to_s + '-' + chday(dd).to_s
  end
end

class Locate_events
  def initialize(today, inputdays)
    @today = today
    @inputdays = inputdays
  end

  def read_task
    db = SQLite3::Database.new('scheduler.db')
    db.results_as_hash = true
    # データベースから
    # タスクの読み込み
    @t_num = 0
    db.execute('select * from task') do |_row|
      @t_num += 1
    end
    @t_id = Array.new(@t_num)
    @t_title = Array.new(@t_num)
    @te_day = Array.new(@t_num)
    @te_time = Array.new(@t_num)
    @tasktime = Array.new(@t_num)
    @c_tasktime = Array.new(@t_num)
    @t_imp = Array.new(@t_num)
    @t_about = Array.new(@t_num)
    @l_tasktime = Array.new(@t_num)
   @t_category = Array.new(@t_num)
    j = 0
    db.execute('select * from task order by e_day asc, e_time  asc, importance asc') do |row|
      @t_id[j] = row['id'].to_s.toutf8
      @t_title[j] = row['title'].to_s.toutf8
      @te_day[j] = row['e_day'].to_s.toutf8
      @tasktime[j] = row['t_time'].to_s.toutf8
      @te_time[j] = row['e_time'].to_s.toutf8
      @t_about[j] = row['about'].to_s.toutf8
      @t_category[j] = row['category'].to_s.toutf8
      @t_imp[j] = row['importance'].to_s.toutf8
      @c_tasktime[j] = row['time'].to_s.toutf8
      @l_tasktime[j] = row['located'].to_s.toutf8
      j += 1
    end
    db.close
  end

  def check_tasktime(id)
    #残りの作業時刻を計算してくれる
    #printf("L114 // call check_tasktime(id=%s)\n", id)
    db = SQLite3::Database.new('scheduler.db')
    db.results_as_hash = true
    db.execute('select * from task where id=?', id) do |row|
      $row4=row[4].to_s
      $row8=row[8].to_s
      $row9=row[9].to_s
      #printf("%s, %s, %s\n", to_min($row4), to_min($row8), to_min($row9))
      $resttime=to_min(row[4].to_s).to_i-(to_min(row[8].to_s).to_i+to_min(row[9].to_s).to_i).to_i
    end
    db.close
    #printf("  L123 // id:%sのresttimeは%s\n", id, $resttime)
    return $resttime
  end

  def read_schedule
    db = SQLite3::Database.new('scheduler.db')
    db.results_as_hash = true
    # データベースから
    # スケジュールの読み込み
    @num = 0
    db.execute('select * from schedule order by s_day asc, s_time asc') do |_row|
      @num += 1
    end
    @title = Array.new(@num)
    @id = Array.new(@num)
    @s_day = Array.new(@num)
    @e_day = Array.new(@num)
    @s_time = Array.new(@num)
    @e_time = Array.new(@num)
    @st = Array.new(@num)
    @category = Array.new(@num)
    @com = Array.new(@num)
    @location = Array.new(@num)
    i = 0
    db.execute('select * from schedule order by s_day asc, s_time asc') do |row|
      @id[i] = row['id'].to_s.toutf8
      @title[i] = row['title'].to_s.toutf8
      @s_day[i] = row['s_day'].to_s.toutf8
      @e_day[i] = row['e_day'].to_s.toutf8
      @s_time[i] = row['s_time'].to_s.toutf8
      @e_time[i] = row['e_time'].to_s.toutf8
      @st[i] = row['st'].to_s.toutf8
      @category[i]=row['category']
      @com[i] = row['completed']
      @location[i] = row['location']
      i += 1
    end
    db.close
  end

  def read_category
    db = SQLite3::Database.new('scheduler.db')
    db.results_as_hash = true
    # データベースから
    # スケジュールの読み込み
    @c_num = 0
    db.execute('select * from category') do |row|
      @c_num += 1
    end
    @c_name = Array.new(@c_num)
    @c_max = Array.new(@c_num)
    @c_min = Array.new(@c_num)
    @c_log = Array.new(@c_num)
    @c_location = Array.new(@c_num)
    i = 0
    db.execute('select * from category') do |row|
      @c_name[i] = row['name'].to_s.toutf8
      @c_max[i] = row['max'].to_s.toutf8
      @c_min[i] = row['min'].to_s.toutf8
      @c_log[i] = row['log'].to_s.toutf8
      @c_location[i] = row['location'].to_s.toutf8
      i += 1
    end
    db.close
  end

  def read_location
    db = SQLite3::Database.new('scheduler.db')
    db.results_as_hash = true
    db.execute('select * from gps order by day desc, time desc limit 1') do |row|
      @location_name=row[1].to_s
    end
    db.close
    return @location_name
 end

  def decide_s_schedule(day)
    #スケジュールを古い順に並び替えて、今日のスケジュールは
    #@num_i+1(0始まり)番目だよと教えてくれるやつ
    read_schedule
    i = 0
    while i < @num.to_i - 1
      if chint(@e_day[i].to_s).to_i - chint(day.to_s).to_i >= 0
        @num_i = i
        break
      else
        i += 1
      end
    end
    # p @num_i, @title[@num_i]
  end

  def decide_e_schedule(day)
    read_schedule
    i = 0
    while i < @num.to_i - 1
      if chint(@s_day[i].to_s).to_i - chint(day.to_s).to_i >0
        @num_i = i
        break
      else
        i += 1
      end
    end
    @num_i=i
    @num_i=@num_i-1
  end

def decide_sday
  day=nextday(@today)
  return day
end

  def decide_eday
    day = @today
    for i in 0.. @inputdays.to_i-1
      day=nextday(day)
    end
    return day
  end

  def search_same(name, sd, st, ed, et)
    decide_s_schedule(@today)
    overlap = 0
    #printf("test: search_same:@num_i=%s",@num_i)
    for i in@num_i.to_i..@num.to_i
      #printf("test: 件名%s...開始%s,終了%s\n", @title[i],@s_day[i],@e_day[i])
      if @title[i] == name && @s_day[i] == sd && @s_time[i] == st && @e_day[i] == ed && @e_time[i] == et
        overlap = 1
        break
      end
    end
    overlap
  end

  def overlap_event(sd, ed, st, et)
    #予定が重複していたら1, 重複してなかったら０
    read_schedule
    decide_s_schedule(sd)
    overlap = 0
    min = Array.new(1339, '0')
    if sd == ed
      for i in to_min(st).to_i..to_min(et).to_i
        min[i] = '1'
      end
    end
    for i in @num_i..@num - 1
      if @s_day[i] == sd
        for i in to_min(@s_time[i]).to_i..to_min(@e_time[i]).to_i
          overlap = 1 if min[i] == '1'
          end
      end
    end
    return overlap
  end

  def null_sleep(sd,ed)
    checkday=nextday(sd)
    decide_s_schedule(checkday)
    s_num=@num_i
    decide_e_schedule(ed)
    e_num=@num_i
    #printf("test: sd%s, ed%s, s_num%s e_num%s\n", sd, ed, s_num, e_num)
    if s_num.to_i>1 && e_num.to_i>1
      for i in s_num..e_num
        if @title[i]=="sleep"
          #printf("test: sleep is %s\n", @s_day[i])
          db = SQLite3::Database.new('scheduler.db')
            db.execute('delete from schedule where id=?', @id[i])
          db.close
        end
      end
    end
  end

  def sleep_t
    day = @today
    #printf("test: def sleep_t, dat=%s\n",day)
    db = SQLite3::Database.new('scheduler.db')
    db.results_as_hash = true
    db.execute('select * from person') do |row|
      $sleep_st=row[1].to_s
      $sleep_et=row[2].to_s
    end
    st=$sleep_st
    et=$sleep_et
    sd=day
    ed=day
    for i in 0..@inputdays.to_i-1
      ed=nextday(ed)
    end
    null_sleep(sd, ed)
    for i in 0..@inputdays.to_i - 1
      s_day = day
      if st.to_i>et.to_i
        e_day = nextday(day)
      else
        e_day=day
      end
      if search_same('sleep', s_day, st, e_day, et) == 0
        db.execute('insert into schedule  (title, s_day, s_time, e_day, e_time, st) values(?, ?, ?, ?, ?, ?)', 'sleep', s_day, st, e_day, et, 's')
      end
      day = nextday(day)
    end
    db.close
  end

  def eating_t(st, et)
    day = @today
    db = SQLite3::Database.new('scheduler.db')
    for i in 0..@inputdays.to_i - 1
      if overlap_event(day, day, st, et)==0
        db.execute('insert into schedule  (title, s_day, s_time, e_day, e_time, st, completed) values(?, ?, ?, ?, ?, ?, ?)', 'ごはん', day, st, day, et, 's', '0')
      else
        #ご飯イベントはないけど、スケジュールがかぶっているとき
     end
      day = nextday(day)
    end
    db.close
  end

  def add_db_log
    #ログ情報をtable"log"にいれる
    wday=["sun", "mon", "tue","wed", "the", "fri", "sat", "sun"]
    d.wday
  end

  def view_event
    read_schedule
    for i in 0..@num - 1
      if i != 0
        print ','
        print "\n"
      end
      print "{\n"
      print "title: '" + @title[i].to_s + "',\n"
      print "id: '" + @id[i].to_s + "',\n"
      if @s_time[i] == '00:00' && @e_time[i] == '24:00'
        print " start: '" + @s_day[i].to_s + "'"
        print ",\n"
        print " end: \'" + @e_day[i].to_s + "\'\n"
        print '}'
      else
        print " start: '" + @s_day[i].to_s + 'T' + @s_time[i].to_s + ":00'"
        print ",\n"
        print " end: '" + @e_day[i].to_s + 'T' + @e_time[i].to_s + ":00'"

        if @st[i].to_s == 's' && @com[i].to_s == ''
          print "\n"
        elsif @st[i].to_s == 's' && @com[i].to_s == '0'
          print ",\n"
          print "color: 'grey'\n"
        elsif @st[i].to_s != 's' && @com[i].to_s == '1'
          print ",\n"
          print "color: 'grey'\n"
        else @st[i].to_s != 's' && @com[i].to_s == ''
          print ",\n"
          print "color: '#cd5c5c'\n"
        end
        print '}'
     end
      i += 1
    end
  end
end

print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
print '<html xmlns="http://www.w3.org/1999/xhtml" lang="ja">'
print '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />'
print '<head><title>Scheduler</title><link rel="shortcut icon" href="http://mima.c.fun.ac.jp/1012151/img/favicon.ico" />'
print_t('sp_js1.txt')
#
# 以下、イベント追加の記述
# ユーザ設定に必要な変数
inputdays = '14'
eat_st = ['08:00', '12:00', '19:30']
eat_et = ['08:30', '13:00', '20:10']

# 翌日から２週間をタスク配置範囲とする
endday = today
today = nextday(today)
for n in 0..365
  # 14日間
  endday = nextday(endday)
end

event = Locate_events.new(today, inputdays)
event.decide_s_schedule(today)
event.sleep_t
for i in 0..2
#  event.eating_t(eat_st[i], eat_et[i])
end
# event.overlap_event("2015-11-04", "2015-11-04", "15:00", "17:00")

event.view_event
print_t('sp_js2.txt')
print '</head>'
print "<body onLoad=\"sendgps()\">"
print_t('index_menu_sp.txt')
print "<hr><div id=\'calendar\'></div>"
print '</body></html>'
