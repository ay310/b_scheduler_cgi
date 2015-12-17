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

def chint(s_data)
  idata = s_data.split('-')
  idata[0].to_s + idata[1].to_s + idata[2].to_s
end

def chday(day)
  day = '0' + day.to_s if day.to_s.length == 1
  day
end
today = d.year.to_s + '-' + chday(d.month).to_s + '-' + chday(d.day).to_s

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
    return day[0].to_i+1+"-01-01"
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
    @com[i] = row['completed']
    @location[i] = row['location']
    @category[i]=row['category']
    i += 1
  end
  db.close
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

def decide_s_schedule(day)
  #スケジュールを古い順に並び替えて、今日のスケジュールは
  #@num_i+1(0始まり)番目だよと教えてくれるやつ
  #返り値@num_i
  read_schedule
  i = 0
  while i < @num.to_i - 1
    if chint(@s_day[i].to_s).to_i - chint(day.to_s).to_i >= 0
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
  @num_i=@num_i-1
end

def total_tasktime(sd, ed)
  decide_s_schedule(sd)
  s_num=@num_i
  decide_e_schedule(ed)
  e_num=@num_i
  tasktime=0
  for i in s_num..e_num
    if @st[i]!="s"
      tasktime=tasktime.to_i+(to_min(@e_time[i]).to_i-to_min(@s_time[i]).to_i)
    end
  end
  return to_h(tasktime)
end

def total_scheduletime(sd, ed)
  decide_s_schedule(sd)
  s_num=@num_i
  decide_e_schedule(ed)
  e_num=@num_i
  stime=0
  for i in s_num..e_num
    if @st[i]=="s"
      if @e_time[i].to_i-@s_time[i].to_i>0
        stime=stime.to_i+(to_min(@e_time[i]).to_i-to_min(@s_time[i]).to_i)
      elsif nextday(@s_day[i].to_s)==@e_day[i].to_s
        stime=stime.to_i+(1440-to_min(@s_time[i]).to_i)+to_min(@e_time[i]).to_i
      end
    end
  end
  return to_h(stime)
end

def category_tasktime(sd, ed, c_name)
  decide_s_schedule(sd)
  s_num=@num_i
  decide_e_schedule(ed)
  e_num=@num_i
  tasktime="0"
  for i in s_num..e_num
    if @category[i]==c_name && @st[i]!="s"
      tasktime=tasktime.to_i+(to_min(@e_time[i]).to_i-to_min(@s_time[i]).to_i)
    end
  end
  return to_h(tasktime)
end

def task_proportion(t_num)
  #printf("%s : %s,%s\n",@t_title[t_num], @c_tasktime[t_num].to_i, @tasktime[t_num].to_i)
  if @c_tasktime=="00:00"
    return 0 +"%"
  else
   c_time=to_min(@c_tasktime[t_num]).to_i
   t_time=to_min(@tasktime[t_num]).to_i
    return (c_time.to_i/t_time.to_i*100).to_s + '%'.to_s
  end
end

prev_num=d.wday.to_i
startday=today
for i in 0..prev_num.to_i+6
  startday=prevday(startday)
  #printf("s_day:%s\n", startday)
end
endday=startday
for i in 0..6
  endday=nextday(endday)
  #printf("e_day:%s\n", endday)
end

read_category
read_task
read_schedule
printf("<html>")
printf("<head>")
printf("<title>feedback</title>")
printf("<script src=\"http://mima.c.fun.ac.jp/1012151/js/Chart.js\"></script>\n")
printf("<link rel='stylesheet' type='text/css'  href=\"http://mima.c.fun.ac.jp/1012151/css/feedback.css\" />\n")
printf("<link rel=\"shortcut icon\" href=\"http://mima.c.fun.ac.jp/1012151/img/favicon.ico\" /></head>\n")
printf("<body>")
printf("<div id=\"layout\"><div id=\"content\">\n")
printf("<h1 id=\"h01\"> %s - %s</h1>\n",startday, endday)
printf("<p>今週のまとめの文章を表示</p>\n")

printf("<h2 id=\"h02\"> 総タスク作業時刻</h2>\n")
t_time=total_tasktime(startday, endday)
s_time=total_scheduletime(startday, endday)
n_time=8640-to_min(t_time).to_i-to_min(s_time).to_i
printf("<p>%s</p>\n",total_tasktime(startday, endday))
printf("<canvas id=\"tasktime\" height=\"200\" width=\"200\"></canvas>\n")
printf("<h2 id=\"h02\"> カテゴリ別作業時刻</h2><br>\n")
printf("<canvas id=\"chart_category\" height=\"200\" width=\"200\"></canvas>\n")

printf("<script type=\"text/javascript\">\n")
printf("var taskData = [\n")
printf("  {\n")
printf("value: %s,\n",to_min(t_time))
printf("color:\"#%s\",\n",rand(0x1000000).to_s(16).rjust(6, '0'))
printf("  highlight: \"#%s\",\n",rand(0x1000000).to_s(16).rjust(6, '0'))
printf("label: \"%s\"\n","タスク作業時刻")
printf("  },\n")
printf("  {\n")
printf("value: %s,\n",to_min(s_time))
printf("color:\"#%s\",\n",rand(0x1000000).to_s(16).rjust(6, '0'))
printf("  highlight: \"#%s\",\n",rand(0x1000000).to_s(16).rjust(6, '0'))
printf("label: \"%s\"\n","スケジュール時刻")
printf("  },\n")
printf("  {\n")
printf("value: %s,\n",n_time)
printf("color:\"#%s\",\n",rand(0x1000000).to_s(16).rjust(6, '0'))
printf("  highlight: \"#%s\",\n",rand(0x1000000).to_s(16).rjust(6, '0'))
printf("label: \"%s\"\n","余暇")
printf("  }];\n")

j=0
printf("var categoryData = [\n")
for i in 0..@c_num.to_i
  c_time=category_tasktime(startday, endday, @c_name[i])
  if c_time!="00:00"
    printf(",") if j!=0
    printf("  {\n")
    printf("value: %s,\n",to_min(c_time))
    printf("color:\"#%s\",\n",rand(0x1000000).to_s(16).rjust(6, '0'))
    printf("  highlight: \"#%s\",\n",rand(0x1000000).to_s(16).rjust(6, '0'))
    printf("label: \"%s\"\n",@c_name[i])
    printf("  }\n")
    j=j+1
  end
end
printf("];\n")
printf("   window.onload = function(){\n")
printf("      var ctx = document.getElementById(\"chart_category\").getContext(\"2d\");\n")
printf("      window.myPie = new Chart(ctx).Pie(categoryData);\n")
printf("      var ctx = document.getElementById(\"tasktime\").getContext(\"2d\");\n")
printf("      window.myPie = new Chart(ctx).Pie(taskData);\n")
printf("   };\n</script><br>\n")
printf("<br><h2 id=\"h02\"> タスク別進捗状況</h2>\n")
for i in 0..@t_num.to_i-1
  t_time=task_proportion(i)

  printf("<p>%s：%s</p>\n",@t_title[i], t_time)
end

printf("<h2 id=\"h02\"> 今週重点を置くべきこと</2>\n")
printf("</div></div>")
printf("</body></html>")
