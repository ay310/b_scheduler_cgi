#!/usr/bin/ruby
# coding: utf-8
require 'cgi'
require 'sqlite3'
require 'kconv'
require 'active_support/all'
data = CGI.new
print "Content-type: text/html\n\n"
#
# 新規作成（in_task.rb）、編集（edit_task）から受け取る変数
#
title = data['title'].to_s.toutf8
e_day = data['e_day'].to_s.toutf8
e_time = data['e_time'].to_s.toutf8
tasktime = data['t_time'].to_s.toutf8
about = data['about'].to_s.toutf8
category = data['category'].to_s.toutf8
star = data['importance'].to_s
e_time == '23:59' if e_time == ''
#
# 編集（edit_task）のみで受け取る変数
#
t_id = data['t_id'].to_s
# 削除
del_id = data['del'].to_s
#
# カレンダー部分からのタスク管理
#
cal_t_id = data['calt_id'].to_s
cal_s_id = data['s_id'].to_s.toutf8
# 以下実際出来た時刻
cal_st = data['cals_time'].to_s.toutf8
cal_et = data['cale_time'].to_s.toutf8
# 以下予定上の時刻
cal_plan_st = data['s_timed'].to_s.toutf8
cal_plan_et = data['e_timed'].to_s.toutf8
cal_memo = data['memo'].to_s.toutf8

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

def to_min(time)
  if time == '00:00'
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
  return hour.to_s + ':' + min.to_s
end

def update_task(t_id, title, e_day, e_time, tasktime, about, category, star)
  db = SQLite3::Database.new('scheduler.db')
  db.results_as_hash = true
  db.execute('update task set title =?  where id=?', title, t_id)
  db.execute('update task set e_time =?  where id=?', e_time, t_id)
  db.execute('update task set e_day =?  where id=?', e_day, t_id)
  db.execute('update task set t_time =?  where id=?', tasktime, t_id)
  db.execute('update task set about =?  where id=?', about, t_id)
  db.execute('update task set category =?  where id=?', category, t_id)
  db.execute('update task set importance =?  where id=?', star, t_id)
  db.close
  print '<html>'
  print '<head><META http-equiv="refresh"; content="0; URL=index.rb"></head><body></body></html>'
end

def add_task(title, e_day, e_time, tasktime, about, category, star)
  db = SQLite3::Database.new('scheduler.db')
  db.results_as_hash = true
  db.execute('insert into task  (title, e_time, e_day, t_time, about, category, importance, time, located) values(?, ?, ?, ?, ?, ?, ?, ?, ?)', title, e_time, e_day, tasktime, about, category, star, '00:00', '00:00')
  db.close
  print '<html>'
  print '<head><META http-equiv="refresh"; content="0; URL=index.rb"></head><body></body></html>'
end

def check_category(category)
  found = 0
  db = SQLite3::Database.new('scheduler.db')
  db.results_as_hash = true
  db.execute('select * from category where name=?', category) do |_row|
    found = 1
  end
  if found == 0
    # カテゴリがまったく新規に作られた場合
    db.execute('insert into category  (name, s, t) values(?, ?, ?)', category, '0', '1')
  else
    # スケジュールで追加されてた場合
    db.execute('update category set t =?  where name=?', '1', category)
  end
  db.close
end

def new_category_view(t_id, title, e_day, e_time, tasktime, star, _about)
  db = SQLite3::Database.new('scheduler.db')
  db.results_as_hash = true
  print_t('in_task1.txt')
  print " <div align=\"center\"><p>タスク入力</p></div> \n"
  print "<br><br><div id = \"main\" style=\"float:left;\"> \n"
  print "<form action=\"/cgi-bin/cal/add_task.rb\" method=\"post\">\n "
  if t_id != ''
    print "<input type=\"hidden\" name=\"t_id\" value=\""
    print t_id
    print "\">"
  end
  print '  <label>件名：</label> '
  print "  <input type=\"text\" name=\"title\" size=\"20\" value=\""
  print title
  print "\">"
  print '  <br><label>締切：</label> '
  print "  <input id=\"e_day\" type=\"text\" name=\"e_day\" value=\""
  print e_day
  print "\">"
  print "  <input id=\"e_time\" type=\"text\" name=\"e_time\" value=\""
  print e_time
  print "\"><br>"
  print '    <label>時間：</label>'
  print "  <input id=\"t_time\" type=\"text\" name=\"t_time\" value=\""
  print tasktime
  print "\"><p>\n"
  print '<label>カテゴリ：</label>'
  print "  <input type=\"text\" name=\"category\" size=\"20\" value=\"新規カテゴリ名\"><br>\n "
  print "<div class=\"hoge\">"
  print '<ul>'
  print "<li><input type=\"radio\" name=\"importance\" value=\"1\""
  print " checked=\"checked\"" if star == '1'
  print '><br>1</li>'
  print "<li><input type=\"radio\" name=\"importance\" value=\"2\""
  print " checked=\"checked\"" if star == '2'
  print '><br>2</li>'
  print "<li><input type=\"radio\" name=\"importance\" value=\"3\""
  print " checked=\"checked\"" if star == '3'
  print '><br>3</li>'
  print '</ul></div>'
  print '  <label>内容：</label>'
  print "  <input type=\"text\" name=\"about\" size=\"20\" value=\"about\"><br>\n"
  print "    <input type=\"submit\" value=\"送信\"  onclick=\"window.close()\" class=\"btn\">\n"
  print '</p></form></div>'
  print_t('in_task3.txt')
  print "  $('#t_time').datetimepicker({	datepicker:false,	format:'H:i',	value:'"
  print tasktime
  print "', step:15});"
  print "$('#e_time').datetimepicker({	datepicker:false,	format:'H:i',	value:'"
  print e_time
  print "', step:5});"
  print "\$(\'#e_day\').datetimepicker({	lang:\'jp\',\n"
  print	"timepicker:false,	value: '"
  print e_day
  print "',	format:'Y-m-d',	formatDate:'Y/m/d',});\n"
  print_t('in_task4.txt')
  db.close
end

def cal_mtime(b_time, a_time)
  r_time = to_min(b_time).to_i - to_min(a_time).to_i
  if r_time.to_i<0
    return 0.to_i
  else
    return r_time.to_i
  end
end

def cal_ptime(b_time, a_time)
  r_time = to_min(b_time).to_i + to_min(a_time).to_i
  return r_time.to_i
end

def task_scheduler(cal_t_id, cal_s_id, cal_st, cal_et, cal_plan_st, cal_plan_et)
  # カレンダーから来た場合の処理
  db = SQLite3::Database.new('scheduler.db')
  db.execute('update schedule set completed =?  where id=?', "1", cal_s_id)
  db.results_as_hash = true
  db.execute('select * from task where id=?', cal_t_id) do |row|
    $t_time = row[4]
    $c_time = row[8]
    $located_time = row[9]
    $log = row[10]
  end
  db.execute('select * from par') do |row|
    $per = row[0]
  end
  db.execute('update task set per=?  where id=?', $per, cal_t_id)
  db.execute('update schedule set s_time=?  where id=?', cal_st, cal_s_id)
  db.execute('update schedule set e_time=?  where id=?', cal_et, cal_s_id)
  plan_tasktime = to_h(to_min(cal_plan_et).to_i - to_min(cal_plan_st).to_i)
  completed_time = to_h(to_min(cal_et).to_i - to_min(cal_st).to_i)
  t = to_h(cal_mtime($located_time, plan_tasktime))
  #配置された時間から、計画していた日時の配置時間を引く
  db.execute('update task set located =?  where id=?', t, cal_t_id)
  tt = to_h(cal_ptime($c_time, completed_time))
  #完了済時間の追加
  plan=to_min(completed_time).to_i-to_min(plan_tasktime).to_i
  if $log.blank?
    new_log=to_min(completed_time).to_s+"(".to_s+plan.to_s+")".to_s
  else
    new_log = $log.to_s+","+to_min(completed_time).to_s+"(".to_s+plan.to_s+")".to_s
  end
  #以下％からタスク時刻を再度決める
  task_time= (100/$per.to_i)*to_min(tt).to_i

  task_time=to_h(task_time).to_s
    printf("task_time is %s. tt is %s\n", task_time, tt)
  db.execute('update task set log =?  where id=?', new_log, cal_t_id)
  db.execute('update task set time =?  where id=?', tt, cal_t_id)
    db.execute('update task set t_time =?  where id=?', task_time, cal_t_id)
  db.close
  print '<html>'
  print '<head><META http-equiv="refresh"; content="0; URL=index.rb"></head><body></body></html>'
end

if cal_t_id != '' && cal_s_id != ''
  #
  # カレンダーから来た場合、以下の処理を行う
  #
  task_scheduler(cal_t_id, cal_s_id, cal_st, cal_et, cal_plan_st, cal_plan_et)
else
  #
  # タスクから来た場合、以下の処理を行う
  #
  if del_id == ''
    # 削除以外のアクション
    if t_id == '' && category == 'no_name'
      # 新規作成時、カテゴリも新規作成が選択された
      # カテゴリフィールドをテキストエリアにして再度表示
      new_category_view('', title, e_day, e_time, tasktime, star, about)
    elsif t_id == '' && category != 'no_name'
      # 新規作成
      # カテゴリは選択済み
      # カテゴリが既にあるものか検証
      # なければ追加、あればそのまま
      check_category(category)
      add_task(title, e_day, e_time, tasktime, about, category, star)

    elsif t_id != '' && category == 'no_name'
      # 編集
      # カテゴリが新規作成
      # テキストエリアで再度表示
      new_category_view(t_id, title, e_day, e_time, tasktime, star, about)
    elsif t_id != '' && category != 'no_name'
      # 編集
      # カテゴリも既存のもの
      # カテゴリの検証
      # なければ追加、あればそのまま
      check_category(category)
      update_task(t_id, title, e_day, e_time, tasktime, about, category, star)
    end
  elsif del_id != ''
    # 削除が選択された場合
    # 該当idの削除
    db = SQLite3::Database.new('scheduler.db')
    db.execute('delete from task where id=?', del_id)
    db.execute('delete from schedule where st=?', del_id)
    db.close
    print '<html>'
    print '<head><META http-equiv="refresh"; content="0; URL=index.rb"></head><body></body></html>'
  else
    p 'error'
  end
end
