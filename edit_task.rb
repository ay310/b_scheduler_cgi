#!/usr/bin/ruby
# coding: utf-8
require 'sqlite3'
require 'cgi'
require 'kconv'
data = CGI.new
print "Content-type: text/html\n\n"

def count(f_name)
  txt = open(f_name, 'r:utf-8')
  t_count = txt.read.count("\n")
  t_count.to_i
end

def print_t(f_name)
  txt = File.open(f_name, 'r:utf-8').readlines
  for i in 0..count(f_name)-1
    print txt[i].to_s
  end
end


# 新規カテゴリ追加時の変数
new_category = data['new_category'].to_s.toutf8
# カテゴリ削除時
del_category = data['del_category']
#既存のタスク編集
t_id = data['taskid'].to_s.toutf8
db = SQLite3::Database.new('scheduler.db')
db.results_as_hash = true
if t_id == ''
 #既存のタスクの編集じゃない時
  if new_category != '新規カテゴリ名' && new_category != ''
  # 新規カテゴリが選択された時
    sql = 'select * from category'
    i = 0
    db.execute(sql) do |row|
      i += 1 if new_category == row['name']
    end
    if i == 0
      db.transaction do
        db.execute('insert into category  (name) values(?)', new_category)
      end
    end
  end

  # カテゴリ削除を選択された時
  if del_category != '' && del_category != '未設定'
    db.execute("update task set category = '未設定' where category=?", del_category)
    db.execute('delete from category where name=?', del_category)
  end
  #print '<html>'
  #print '<head><META http-equiv="refresh"; content="0; URL=/cgi-bin/cal/view_task.rb"></head><body></body></html>'
else
  #既存のタスクの編集のとき
  print_t('in_task1.txt')
  num=0
  db.execute('select * from task') do |_row|
    num =num+1
  end
  $t = Array.new(num)
  $id = Array.new(num)
  $e_day = Array.new(num)
  $t_time = Array.new(num)
  $e_time = Array.new(num)
  $about = Array.new(num)
  $category = Array.new(num)
  $im = Array.new(num)
  j = 0
  db.execute('select * from task') do |row|
    $id[j] = row['id'].to_s
    $t_num = j if $id[j].to_i == t_id.to_i
    $t[j] = row['title'].to_s
    $e_day[j] = row['e_day'].to_s
    $t_time[j] = row['t_time'].to_s
    $e_time[j] = row['e_time'].to_s
    $about[j] = row['about'].to_s
    $category[j] = row['category'].to_s
    $im[j] = row['importance'].to_s
    j=j+1
  end
  print " <div align=\"center\"><p>タスク入力</p></div>\n "
  print "<br><br><div id = \"main\" style=\"float:left;\">\n "
  print "<form action=\"add_task.rb"
  print"\" method=\"post\">\n "
  print "<input type=\"hidden\" name=\"t_id\" value=\""
  print $id[$t_num]
  print "\">"
  print '  <label>件名：</label> '
    print "\n"
  print "  <input type=\"text\" name=\"title\" size=\"20\" value=\""
  print $t[$t_num]
  print "\">"
  print '  <br><label>締切：</label> '
    print "\n"
  print "  <input id=\"e_day\" type=\"text\" name=\"e_day\" value=\""
  print $e_day[$t_num]
  print "\">"
  print "  <input id=\"e_time\" type=\"text\" name=\"e_time\" value=\""
  print $e_time[$t_num]
  print "\"><br>"

  print '    <label>時間：</label>'
    print "\n"
  print "  <input id=\"t_time\" type=\"text\" name=\"t_time\" value=\""
  print $t_time[$t_num]
  print "\"><p>"
  print '<label>カテゴリ：</label>'
    print "\n"
  print '<select name="category">'
  c_name = Array.new(num)
  k = 0
  db.execute('select * from category') do |row|
    c_name[k] = row[0]
    print "<option value=\""
    print c_name[k]
    if $category[$t_num]==c_name[k]
     print "\" selected>"
     else
    print "\">"
    end
    print c_name[k]
    print "</option>\n"
    k += 1
  end
  print "<option value=\"no_name\">新規作成</option>\n"
  print '  </select>'
  print "<div class=\"hoge\">"
  print "<ul>"
  print "<li><input type=\"radio\" name=\"importance\" value=\"1\""
  if $im[$t_num]=="1"
  print  " checked=\"checked\""
  end
  print "><br>1</li>"
  print "<li><input type=\"radio\" name=\"importance\" value=\"2\""
  if $im[$t_num]="2"
  print  " checked=\"checked\""
  end
  print "><br>2</li>"
  print "<li><input type=\"radio\" name=\"importance\" value=\"3\""
  if $im[$t_num]=="3"
  print  " checked=\"checked\""
  end
  print "><br>3</li>"
  print "</ul></div>"
  print '  <label>内容：</label>'
    print "\n"
  print " <input type=\"text\" name=\"about"
  print "\" size=\"20\" value=\""
  print  $about[$t_num]
  print "\"><br>"
  print "<input type=\"submit\" value=\"OK\"  onclick=\"window.close()\" class=\"btn\">"
  print '</p></form></div><br>'
  print "<div id = \"buttom\" align=\"right\" style=\"clear:both;\"></div>"
  print "<form action=\"add_task.rb"
  print"\" method=\"post\">\n "
  print "<input type=\"hidden\" name=\"del\" value=\""
  print $id[$t_num]
  print "\">"
  print "<input type=\"submit\" value=\"削除\"  onclick=\"window.close()\" class=\"btn\">"
  print "</form></div></div>"
print_t('in_task3.txt')
print"  $('#t_time').datetimepicker({	datepicker:false,	format:'H:i',	value:'"
print $t_time[$t_num]
print "', step:15});"
 print"$('#e_time').datetimepicker({	datepicker:false,	format:'H:i',	value:'"
 print $e_time[$t_num]
 print "', step:5});"

  d = Date.today

  def time(number)
    if number.length == 1
      return number = '0' + number
    else
      return number
    end
  end

  month = time(d.month.to_s.chomp)
  day = time(d.day.to_s.chomp)

  print "  $('#e_day').datetimepicker({"
  print "lang:'jp',"
  print 'timepicker:false,'
  print "value: '"
print $e_day[$t_num]
  print "',"
  print	"format:'Y-m-d',"
  print "formatDate:'Y/m/d',});"

  print_t('in_task4.txt')
end
db.close
