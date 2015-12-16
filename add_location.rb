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

  print " <!DOCTYPE html><html lang=\"ja\"><head><meta charset=\"utf-8\">"
  print "<title>Scheduler　ー　位置情報の追加</title>"
  print "<link rel=\"stylesheet\" href=\"css/task.css\">"
  print "<script language=\"JavaScript\">function mySubmit( place ) {document.form1.allday.value = place;document.form1.submit();}</script>"
  print "</head><body>"
  print "<div id=\"layout\"><div id=\"content\">"
  print "  <form action=\"send_gps.rb\" method=\"get\">"
print "  <p>現在地名：<input type=\"text\" name=\"addlocation\"></p>"
print "<p><input type=\"submit\" value=\"送信\"> "
print "</form>"
print "<form><INPUT type=\"button\" onClick='history.back();' value=\"戻る\" class=\"btn\"></p>"
print "</form></div></div>\n"
print '</body></html>'
