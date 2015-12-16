#!/usr/bin/ruby
# coding: utf-8
require 'cgi'
require 'sqlite3'
require 'kconv'
data = CGI.new
print "Content-type: text/html\n\n"

db = SQLite3::Database.new('scheduler.db')
db.results_as_hash = true
sql = 'select * from task'
$num = 0
db.execute(sql) do |row|
  $num += 1
end

$t = Array.new($num)
$id = Array.new($num)
$e_day = Array.new($num)
$t_time = Array.new($num)
$e_time = Array.new($num)
$about = Array.new($num)
$category = Array.new($num)
$importance = Array.new($num)
$i = 0

print '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
print "\n "
print '<html xmlns="http://www.w3.org/1999/xhtml" lang="ja"> '
print "\n "
print '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /> '
print "\n "
print '<head> '
print '<title>Scheduler</title>'
print "\n "
print "<link href=\"http://mima.c.fun.ac.jp/1012151/css/task.css\" rel=\"stylesheet\">"
print '</head> '
print "\n "
print '<body>'
print '<div id="left-side" style="float:left;">'
print "\n "
print "<form action=\"edit_task.rb\" method=\"post\">\n "
 $i=0
db.execute(sql) do |row|
  $id[$i] = row['id'].to_s
  $t[$i] = row['title'].to_s
  $e_day[$i] = row['e_day'].to_s
  $t_time[$i] = row['t_time'].to_s
  $e_time[$i] = row['e_time'].to_s
  $about[$i] = row['about'].to_s
  $category[$i] = row['category'].to_s
  $importance[$i] = row['importance'].to_s
  print "<input type=\"radio\" value=\""
  print $id[$i]
  print "\" name=\"taskid\">"
  print $t[$i].to_s
  print "\n<br>\n"
  print $about[$i].to_s
    print "\n<br>\n"
  print "締切："
  print $e_day[$i]
  print  $e_time[$i].to_s
    print "\n<br>\n"
  print "作業時間："
  print  $t_time[$i].to_s
    print "\n<br>\n"
  print "カテゴリ："
  print $category[$i]
  print '<br><br>'
      print "\n "
end
print "   <input type=\"submit\" value=\"編集\" class=\"btn\"></p>\n  "
print ' </form> '

print "\n "
$num = 0
sql = 'select * from category'
db.execute(sql) do |row|
  $num += 1
end
  print '<br><br>'
  print "</div>\n"
print '<div id="right-side" style="float:right;">'
# カテゴリ追加メニュー
print 'カテゴリの追加：'
print "<form action=\"edit_task.rb\" method=\"post\">\n "
print "  <input type=\"text\" name=\"new_category\" size=\"20\" value=\"新規カテゴリ名\">\n  "
print "   <input type=\"submit\" value=\"追加\"  onclick=\"window.close()\" class=\"btn\"></p>\n  "
print ' </form> '

# カテゴリ削除メニュー
print 'カテゴリの削除：'
print "\n "
print "<form action=\"edit_task.rb\" method=\"post\"> \n "
print "  <select name=\"del_category\">\n  "
$c_name = Array.new($num)
$i = 0
db.execute(sql) do |row|
  $c_name[$i] = row[0]
  print "<option value=\""
  print $c_name[$i]
  print "\">"
  print $c_name[$i]
  print "</option>\n "
  $i += 1
end
print '  </select> '
print "\n "
print "<input type=\"submit\" value=\"削除\"  onclick=\"window.close()\" class=\"btn\"></p>\n  "
print '  </form>'
print "\n "

print "<a href=\"index.rb\">もどる</a>\n "
print "</div>\n"
print '</body></html>'
print "\n "
db.close
