#!/usr/bin/ruby
# coding: utf-8
require 'cgi'
require 'date'
require 'sqlite3'
require 'kconv'
data = CGI.new
print "Content-type: text/html\n\n"

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

print_t("in_task1.txt")
print_t("in_task2.txt")

db = SQLite3::Database.new('scheduler.db')
i = 0
num =0
db.execute('select * from category where t=?', "1") do |_row|
  num += 1
end

print '<label>カテゴリ：</label>'
print '<select name="category">'
c_name = Array.new(num)
db.execute('select * from category where t=?', "1") do |row|
  c_name[i] = row[0]
  print "<option value=\"#{c_name[i].to_s.chomp}\">#{c_name[i].to_s.chomp}</option>"
  i += 1
end
print "<option value=\"no_name\">新規作成</option>"
print '  </select>'
print "<div class=\"hoge\">"
print "<ul><li><input type=\"radio\" name=\"importance\" value=\"1\"><br>1</li>"
print "<li><input type=\"radio\" name=\"importance\" value=\"2\" checked=\"checked\"><br>2</li>"
print "<li><input type=\"radio\" name=\"importance\" value=\"3\"><br>3</li>"
print "</ul></div>"
print "  <label>内容：</label>"
print " <input type=\"text\" name=\"about\" size=\"20\" value=\"about\"><br>"
print "    <input type=\"submit\" value=\"送信\"  onclick=\"window.close()\" class=\"btn\">"
print "</p></form></div>"
print "<div id=\"allday\" style=\"float:right;\"></div><br>"
print "<div id = \"buttom\" align=\"right\" style=\"clear:both;\">"
print "<form><INPUT type=\"button\" onClick='history.back();' value=\"戻る\" class=\"btn\">"
print "</form></div></div>"
print_t("in_task3.txt")
print"  $('#t_time').datetimepicker({	datepicker:false,	format:'H:i',	value:'"
print "01:00"
print "', step:15});"
 print"$('#e_time').datetimepicker({	datepicker:false,	format:'H:i',	"
 print "value:'23:59',"
 print "step:5});"
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

print "$('#s_day').datetimepicker({	lang:'jp',"
print "timepicker:false,"
print "value: '#{d.year}-#{month}-#{day}',"
print "format:'Y-m-d',	formatDate:'Y/m/d',});"
print"  $('#e_day').datetimepicker({"
print "lang:'jp',"
print "timepicker:false,"
print "value: '#{d.year}-#{month}-#{day}',"
print	"format:'Y-m-d',"
print "formatDate:'Y/m/d',});"

print_t("in_task4.txt")
