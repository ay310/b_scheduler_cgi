#!/usr/bin/ruby
# coding: utf-8
require 'cgi'
require 'date'
require 'sqlite3'
require 'kconv'
data = CGI.new
print "Content-type: text/html\n\n"
st = data['sleep_st'].to_s.toutf8
et = data['sleep_et'].to_s.toutf8

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

def time(number)
  if number.length == 1
    return number = '0' + number
  else
    return number
  end
end
i = 0
num = 0

if st=="" && et==""
print_t("in_task1.txt")
  db = SQLite3::Database.new('scheduler.db')
  db.execute('select * from person where id=?', "1") do |row|
    $sleep_st= row[1].to_s
    $sleep_et = row[2].to_s
  end

  print "<div align=\"center\"><p>情報の編集</p></div>"
  print "<br><br><div id = \"main\" style=\"float:left;\">"
  print "  <form action=\"personal.rb\" method=\"post\">"
  print "  <br><label>睡眠時刻：</label>"
  print "  <input id=\"sleep_st\" type=\"text\" name=\"sleep_st\">"
  print "〜"
  print "  <input id=\"sleep_et\" type=\"text\" name=\"sleep_et\"><br>"
  print "    <input type=\"submit\" value=\"送信\"  onclick=\"window.close()\" class=\"btn\">"
  print "</p></form></div>"
  print "<div id=\"allday\" style=\"float:right;\"></div><br>"
  print "<div id = \"buttom\" align=\"right\" style=\"clear:both;\">"
  print "<form><INPUT type=\"button\" onClick='history.back();' value=\"戻る\" class=\"btn\">"
  print "</form></div></div>\n"
  print_t("in_task3.txt")
  print"  $('#sleep_st').datetimepicker({	datepicker:false,	format:'H:i',\n	value:'"
  print $sleep_st
  print "', step:10});\n"
  print"$('#sleep_et').datetimepicker({	datepicker:false,	format:'H:i',\n		value:'"
  print $sleep_et
  print "', step:10});\n"
  d = Date.today
  month = time(d.month.to_s.chomp)
  day = time(d.day.to_s.chomp)
  db.close
  print_t("in_task4.txt")
else
  db = SQLite3::Database.new('scheduler.db')
  db.results_as_hash = true
  db.execute('update person set sleep_st =?  where id=?', st, "1")
  db.execute('update person set sleep_et =?  where id=?', et, "1")
  db.close
  print '<html>\n'
  print '<head><META http-equiv="refresh"; content="0; URL=index.rb"></head><body></body></html>'
end
