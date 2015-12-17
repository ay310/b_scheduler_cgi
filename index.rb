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

  def add_db_task(i, inputday, st, et)
    #printf("test: !!call add_db_task (%s, %s, %s, %s)\n", i, inputday, st, et)
    #p num
    #printf("test: i:%s, s:%s, st:%s, et:%s\n", i, s, st, et)
  	db = SQLite3::Database.new('scheduler.db')
  	db.execute('insert into schedule  (title, s_day, s_time, e_day, e_time, category, st, completed) values(?, ?, ?, ?, ?, ?, ?, ?)', @t_title[i], inputday, st, inputday, et, @t_category[i], @t_id[i], '0')
    if @l_tasktime[i]=="00:00"
      @l_tasktime[i]=to_h(to_min(et).to_i-to_min(st).to_i)
    else
      @l_tasktime[i]=to_h(to_min(@l_tasktime[i]).to_i + (to_min(et).to_i-to_min(st).to_i))
    end
  	db.execute('update task set located = ? where id=?', @l_tasktime[i], @t_id[i])
  	db.close
    read_task
  	check_tasktime(@t_id[i])
  end


  def task_add_time(s_time, e_time, b_time, task, c, inputday, i, flag)
    #printf("test: L386: %s(%s):%s, b_time is %s,  c is %s\n",@t_title[i].to_s, i, task, b_time, c)
    b_time = b_time.to_i-20
    if b_time.to_i<10
    elsif b_time.to_i>0
      #stとetを決める sの追加はput_taskでやったもらったほうがよいかも
      if flag=="0"
        if @c_min[c].to_i>b_time.to_i
        else
          if @c_min[c].to_i>task
            task=@c_min[c].to_i
            add_time=@c_min[c].to_i-task.to_i
            new_tasktime=to_h(to_min(@tasktime[i]).to_i+add_time.to_i)
            @tasktime[i]=new_tasktime
            db = SQLite3::Database.new('scheduler.db')
              db.execute('update task set t_time = ? where id=?', @tasktime[i], @t_id[i])
            db.close
            task=@c_min[c].to_i
            #printf("test: L403 new_task:%s\n",task)
              #ここまで、タスクがc_min以下だった場合タスク時間をc_minの差分分増やす
          end
          if b_time.to_i >task.to_i
            #printf("test: call392 c_max is %s\n",@c_max[c])
            if task.to_i > @c_max[c].to_i
              #printf("test: call394n")
              #ad c_max
              st=to_h(to_min(e_time).to_i+10)
              et=to_h(to_min(st).to_i+@c_max[c].to_i)
              add_db_task(i, inputday, st, et)
            elsif task.to_i <= @c_max[c].to_i
              #ad task
              st=to_h(to_min(e_time).to_i+10)
              et=to_h(to_min(st).to_i+task.to_i)
              #printf("test: call403\n")
              add_db_task(i, inputday, st, et)
            end
          else
            if b_time.to_i>@c_max[c].to_i
              #ad c_mac
              st=to_h(to_min(e_time).to_i+10)
              et=to_h(to_min(st).to_i+@c_max[c].to_i)
              #printf("test: call411\n")
              add_db_task(i, inputday, st, et)
            elsif b_time.to_i < @c_max[c].to_i
              #ad b_time
              st=to_h(to_min(e_time).to_i+10)
              et=to_h(to_min(st).to_i+b_time.to_i)
              #printf("test: call417(st:%s, et%s, b_time:%s)\n", st, et, b_time)
              add_db_task(i, inputday, st, et)
            end
          end
        end
      elsif flag.to_s=="c"
        #カテゴリ一緒の時
        #寝起きの痕は準備とかあるので２時間取ります
        #printf("call flag sleep!\n")
        b_time=b_time.to_i-150
        if b_time.to_i>@c_min[c].to_i
          if task.to_i<b_time.to_i
            if task.to_i>@c_max[c].to_i
              st=to_h(to_min(e_time).to_i+120)
              et=to_h(to_min(st).to_i+@c_max[c].to_i)
              add_db_task(i, inputday, st, et)
            elsif task.to_i<=@c_max[c].to_i
              st=to_h(to_min(e_time).to_i+120)
              et=to_h(to_min(st).to_i+task.to_i)
              #printf("test: call456(st:%s, et%s, b_time:%s)\n", st, et, b_time)
              add_db_task(i, inputday, st, et)
            end
          elsif
            #task>=b_time
            if b_time.to_i>@c_max[c].to_i
              st=to_h(to_min(e_time).to_i+120)
              et=to_h(to_min(st).to_i+@c_max[c].to_i)
              #printf("test: call464(st:%s, et%s, b_time:%s)\n", st, et, b_time)
              add_db_task(i, inputday, st, et)
            else
              st=to_h(to_min(e_time).to_i+120)
              et=to_h(to_min(st).to_i+b_time.to_i)
              #printf("test: call469(st:%s, et%s, b_time:%s)\n", st, et, b_time)
              add_db_task(i, inputday, st, et)
            end
          end
        end
      elsif flag.to_s=="sleep"
        #flagがsleepの時
        #寝起きの痕は準備とかあるので２時間取ります
        #printf("call flag sleep!\n")
        b_time=b_time.to_i-150
        if b_time.to_i>@c_min[c].to_i
          if task.to_i<b_time.to_i
            if task.to_i>@c_max[c].to_i
              st=to_h(to_min(e_time).to_i+120)
              et=to_h(to_min(st).to_i+@c_max[c].to_i)
              add_db_task(i, inputday, st, et)
            elsif task.to_i<=@c_max[c].to_i
              st=to_h(to_min(e_time).to_i+120)
              et=to_h(to_min(st).to_i+task.to_i)
              #printf("test: call456(st:%s, et%s, b_time:%s)\n", st, et, b_time)
              add_db_task(i, inputday, st, et)
            end
          elsif
            #task>=b_time
            if b_time.to_i>@c_max[c].to_i
              st=to_h(to_min(e_time).to_i+120)
              et=to_h(to_min(st).to_i+@c_max[c].to_i)
              #printf("test: call464(st:%s, et%s, b_time:%s)\n", st, et, b_time)
              add_db_task(i, inputday, st, et)
            else
              st=to_h(to_min(e_time).to_i+120)
              et=to_h(to_min(st).to_i+b_time.to_i)
              #printf("test: call469(st:%s, et%s, b_time:%s)\n", st, et, b_time)
              add_db_task(i, inputday, st, et)
            end
          end
        end
      else
        #flag==sのとき
        if@c_max[c].to_i>task.to_i
          if b_time.to_i+60>task.to_i
            st=to_h(to_min(e_time).to_i+30)
            et=to_h(to_min(st).to_i+task.to_i)
            add_db_task(i, inputday, st, et)
          elsif b_time.to_i+60<=task.to_i
          end
        end
      end
    end
  end



  def put_task
    read_schedule
    read_task
    decide_s_schedule(@today)
    s=@num_i.to_i
  #  printf("call put_task\n")
    #タスクのeventの追加処理
    #スケジュールを日付順に並べ替え、@num_i番目が今日＋１日目のスケジュール
    #@s_day[s]が今日＋１日めのスケジュール
    endday=decide_eday
    day=decide_sday
    #s_day[@num_i]~enddayまでの間にスケジュールを追加する
    #タスクiのカテゴリは@c_name[c]である
    read_task
    read_category
    i=0
  #  printf("t_num:%s\n",@t_num)
    until i==@t_num
      check_tasktime(@t_id[i])
      #printf("test:L472 iは%s,　resttimeは%s\n", i, $resttime)
      #タスクの残り作業時刻の計測
      #$resttimeが変数
      #printf("%s i:%s, 残作業時刻は%s\n", @t_title[i], i, $resttime)
      if $resttime!=0
        endday=@te_day[i]
        for j in 0.. @c_num.to_i-1
          #カテゴリテーブルのカテゴリj
          if @t_category[i]==@c_name[j]
            #現在のタスクiのカテゴリ名がカテゴリとヒットした時
            c=j
            break;
          end
        end
        #↑カテゴリ検索end
        checkday=@today
        #printf("test:checkday=%s\n", checkday)
        if prevday(checkday)==endday && $resttime>0
          #開いた当日が締切日の場合
          #printf("L490 開いた当日が締切日の場合\n")
          for j in 0..@num.to_i-1
            if endday==@e_day[j]
              s=j
              break
            end
          end
          if @e_day[s]==@s_day[s+1]
            b_time=to_min(@s_time[s+1]).to_i-to_min(@e_time[s]).to_i
            task_add_time(@s_time[s+1], @e_time[s], b_time,$resttime, c, endday, i, "0")
          end
        end
        #当日締切end
        until chint(checkday)>chint(endday)
          #printf("(%s:%s) test:checkyday=%s, %s:@e_day[s]=%s\n", i, @t_title[i],  checkday, @title[s],@e_day[s])
          if $resttime<=0
            #printf("test: break %s\n", i)
            break;
          end
          #  printf("checkday : %s, endday : %s\n",checkday, endday)
          while chint(checkday).to_i>chint(@e_day[s]).to_i
            s=s+1
          end
          #printf("test: %s, %s\n",@e_day[s], @s_day[s+1])
          if checkday==@e_day[s]
            #指定日に予定がある
            if @e_day[s]==@s_day[s+1]
              #その次の予定も同日である
              if @category[s].to_s==@c_name[c].to_s
                b_time=to_min(@s_time[s+1]).to_i-to_min(@e_time[s]).to_i
                #printf("519 / test: b_time is %s\n", b_time)
                task_add_time(@s_time[s+1], @e_time[s], b_time,$resttime, c, checkday, i, "0")
                s=s+1
              elsif @category[s]==nil
                b_time=to_min(@s_time[s+1]).to_i-to_min(@e_time[s]).to_i
                #printf("524 / b_time is %s\n", b_time)
                task_add_time(@s_time[s+1], @e_time[s], b_time, $resttime, c, checkday, i, "sleep")
                s=s+1
              else
                s=s+1
              end
            else
              #printf("test: L518//%s\n", @e_time[s])
              if to_min(@e_time[s]).to_i < to_min("12:00")
                s=s+1#タスクを配置する
              end
            end
          else
            #指定日に予定がない
          end
          if chint(checkday).to_i < chint(@e_day[s]).to_i
            checkday=nextday(checkday)
          end
        end
        #checkdayが締め切りになるまで
        if $resttime!=0
          #printf("test 530/call not_same_category:%s\n",i)
          #以下、カテゴリどうし近しいものが無かった場合強制的に追加
          checkday=@today
          decide_s_schedule(@today)
          s=@num_i.to_i
            #printf("test: L536/ endday=%s\n", endday)
          until chint(checkday)>chint(endday)
            #printf("test: L536/ checkday=%s\n", checkday)
            if $resttime==0
              break;
            end
            while chint(checkday).to_i>chint(@e_day[s]).to_i
              s=s+1
            end
            if chint(checkday).to_i < chint(@e_day[s]).to_i
              checkday=nextday(checkday)
            end
            if checkday==@e_day[s]
              if @e_day[s]==@s_day[s+1]
                b_time=to_min(@s_time[s+1]).to_i-to_min(@e_time[s]).to_i
                #printf("565 / b_time is %s\n", b_time)
                task_add_time(@s_time[s+1], @e_time[s], b_time, $resttime, c, checkday, i, s)
                s=s+1
              else
                #同日に次の予定がない場合
              end
            else
              #指定日に予定がない
            end
          end
        end
        i=i+1
        decide_s_schedule(@today)
        s=@num_i.to_i
      else
        #resttimeが0の時
        i=i+1
        decide_s_schedule(@today)
        s=@num_i.to_i
      end
      #↑resttime!=0 end
    end
    #↑until i==@t_num end
  end

  def null_task
    #printf("test:[call null_task]!\n")
    read_task
    searchday=@today
    decide_s_schedule(@today)
    s=0
    db = SQLite3::Database.new('scheduler.db')
      #printf("test:@s_name[%s]:%s\n", s, @title[s])
      #printf("test: @num-1=%s\n",@num-1)
    while s!=@num-1
      #printf("test:@s_name[%s]:%s\n", s, @title[s])
      if chint(searchday).to_i < chint(@e_day[s]).to_i
        searchday=nextday(searchday)
      end
      #printf("test: s=%s, com=%s searchday:%s, sday[s]:%s\n",s, @com[s], searchday, @s_day[s])
      #printf("test: prevday=%s\n", prevday(@today))
      if prevday(@today)!=@s_day[s] && @com[s]==0
        #printf("test: delete %s(id:%s)\n",@title[s], @id[s])
        db.execute('delete from schedule where id=?', @id[s])
        del_min=to_min(@e_time[s]).to_i-to_min(@s_time[s]).to_i
        for i in 0.. @t_num-1
          if @st[s]==@t_id[i]
            id=i
            break
          end
        end
        #printf("test:%s del_min=%s, id=%s\n", @t_title[id], del_min, @t_id[id])
        #printf("id:%s, \n", id)
        new_located=to_h(to_min(@l_tasktime[id]).to_i-del_min.to_i)
        #printf("test:%s located=%s, id=%s\n", @t_title[id], new_located, @t_id[id])
        db.execute('update task set located = ? where id=?', new_located, @t_id[id])
        @l_tasktime[id]=new_located
        #printf("test: @l_tasktime[%s]:%s\n",id, @l_tasktime[id])
      end
      s=s+1
    end
    db.close
    put_task
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

  def view_taskmenu
    read_task
    print_t('body1.txt')
    printf("<p><a href=\"feedback.rb\"><b>振り返る</b></a></p>\n")
    print "<p>現在地は"
    print read_location.to_s
    print "です\n"
    print "→<a href=\"add_location.rb\" alt=\"タスクの入力\">現在地の入力</a></p>\n"
    print " <p>新規作成：<a href=\"new_schedule.rb\">スケジュール</a> / \n"
    print "<a href=\"in_task.rb\" alt=\"タスクの入力\">タスク</a></p>\n"
    print "<p>編集：<a href=\"edit_category.rb\">カテゴリ</a> / \n"
    print "<a href=\"personal.rb\" alt=\"個人情報の編集\">個人情報</a></p>\n"
    print "</div><br>\n"
    print "<b>||| Task</b><div class='box-lid-menulist'>\n"
    print "<FORM name=\"form1\" action=\"edit_task.rb\" onSubmit=\"return false\">\n"
    print "<INPUT type=\"hidden\" name=\"taskid\" value=\""
    print "\">"
    for i in 0..@t_num-1.to_i
      if @tasktime[i].to_s!=@c_tasktime[i].to_s
        print "<INPUT type=\"radio\" onClick=\"mySubmit('"
        print @t_id[i]
        print "')\"> "
        print '<b>' if @t_imp[i] == '3'
        print @t_title[i]
        print '</b>' if @t_imp[i] == '3'
        print ' ('
        print to_h(to_min(@tasktime[i]).to_i - to_min(@c_tasktime[i]).to_i)
        print ')'
        print "</br>\n"
        print '<div class=\'box-lid-menu-postscript\'>〆 '
        print @te_day[i]
        print ', '
        print @te_time[i]
        print '<br>'
        print @t_about[i]
        print "</div>\n"
      end
    end
    print "<div id = \"buttom\" align=\"right\" style=\"clear:both;\"></div>\n"
    print ' </form></div> '

    print "<b>||| 完了済みTask</b><div class='box-lid-menulist'>\n"
    print "<FORM name=\"form2\" action=\"edit_task.rb\" onSubmit=\"return false\">\n"
    print "<INPUT type=\"hidden\" name=\"taskid\" value=\""
    print "\">"
    for i in 0..@t_num-1.to_i
      if @tasktime[i].to_s==@c_tasktime[i].to_s
        print "<INPUT type=\"radio\" onClick=\"mySubmit('"
        print @t_id[i]
        print "')\"> "
        print @t_title[i]
        print "</br>\n"
        print '<div class=\'box-lid-menu-postscript\'>〆 '
        print @te_day[i]
        print ', '
        print @te_time[i]
        print '<br>'
        print @t_about[i]
        print "</div>\n"
      end
    end
    print "<div id = \"buttom\" align=\"right\" style=\"clear:both;\"></div>\n"
    print ' </form></div> '
    print_t('body2.txt')
  end
end

print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
print '<html xmlns="http://www.w3.org/1999/xhtml" lang="ja">'
print '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />'
print '<head><title>Scheduler</title><link rel="shortcut icon" href="http://mima.c.fun.ac.jp/1012151/img/favicon.ico" />'
print '<script type="text/javascript" src="http://mima.c.fun.ac.jp/1012151/js/userAgent.js"></script>'
print_t('js1.txt')
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
#event.overlap_event("2015-11-04", "2015-11-04", "15:00", "17:00")
#event.null_task

event.view_event
print_t('js2.txt')
print '</head>'
print '<body onLoad="sendgps()">'
event.view_taskmenu
print '</body></html>'
