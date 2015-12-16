#!/usr/bin/ruby
# coding: utf-8
require 'cgi'
require 'sqlite3'
require 'kconv'
data = CGI.new

id = data['id'].to_i
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
print "Content-type: text/html\n\n"
db = SQLite3::Database.new('scheduler.db')
sql = 'SELECT * FROM schedule WHERE id == ?'
db.execute('select * from schedule where id=?', id) do |row|
  $title = row[1]
  $s_day = row[2]
  $e_day = row[4]
  $s_time = row[3]
  $e_time = row[5]
  $st = row[8]
  $cate = row[6]
end

if $st != 's'
  # カレンダーからタスクが選択された時
  db.execute('select * from task where id=?', $st) do |row|
    $per = row[11]
  end
  print_t('calendar_task1.txt')
  printf("value: %s,\n",$per.to_i)
  printf("min: 1,\n")
  printf("max: 100,\n")
  print_t('calendar_task2.txt')
  print "<form action=\"add_task.rb"
  print "\" method=\"post\">\n "
  print "<input type=\"hidden\" name=\"s_id\" value=\""
  print id
  print "\">\n"
  print "<input type=\"hidden\" name=\"calt_id\" value=\""
  print $st
  print "\">\n"
  print "<input type=\"hidden\" name=\"s_timed\" value=\""
  print $s_time
  print "\">\n"
  print "<input type=\"hidden\" name=\"e_timed\" value=\""
  print $e_time
  print "\">\n"
  print '  <p><label>件名：</label> '
  print "\n"
  print "  <input type=\"text\" name=\"title\" size=\"20\" value=\""
  print $title
  print "\"></p>\n"
  print '    <label>作業時間：</label>'
  print "\n"
  print "  <input id=\"cals_time\" type=\"text\" name=\"cals_time\" value=\""
  print $s_time
  print "\">〜"
  print "  <input id=\"cale_time\" type=\"text\" name=\"cale_time\" value=\""
  print $e_time
  print "\">\n"
  print ' <p>'
  print ' <label for="amount">全体の進捗状況を入力:</label>'
  print '   <input type="text" id="amount" style="border: 0; color: #f6931f; font-weight: bold;" />'
  print ' </p>'
  print ' <div id="slider-range-min"></div>'
  print '  <p><label>メモ</label></p>'
  print "\n"
  print " <textarea rows=\"3\" name=\"memo"
  print "\" size=\"20\" value=\""
  # print  $about[$t_num]
  print "\"></textarea><br>\n"
  print "<div align=\"right\"><input type=\"submit\" value=\"OK\"  onclick=\"window.close()\" class=\"btn_submit\">"
  print '</div></form></div><br>;\n'
  print "<div id = \"buttom\" align=\"right\" style=\"clear:both;\"></div>\n"
  print '</div></div>'
  print_t('in_task3.txt')
  print "  $('#cals_time').datetimepicker({	datepicker:false,	format:'H:i',	value:'"
  print $s_time
  print "', step:15});\n"
  print "$('#cale_time').datetimepicker({	datepicker:false,	format:'H:i',	value:'"
  print $e_time
  print "', step:5});\n"
  d = Date.today
  month = time(d.month.to_s.chomp)
  day = time(d.day.to_s.chomp)
  print "  $('#e_day').datetimepicker({"
  print "lang:'jp',"
  print 'timepicker:false,'
  print "value: '"
  # print $e_day[$t_num]
  print "',"
  print	"format:'Y-m-d',"
  print "formatDate:'Y/m/d',});"
  print_t('calendar_task3.txt')
elsif $st == 's'
  # スケジュールをクリックした時
  print '<!DOCTYPE html>' + "\n"
  print '<html lang="ja">' + "\n"
  print '<head>' + "\n"
  print '<meta charset="utf-8">' + "\n"
  print '<title>Scheduler ー　予定の編集・削除</title>' + "\n"
  print '<link rel="stylesheet" href="http://mima.c.fun.ac.jp/1012151/jquery.datetimepicker.css">' + "\n"
  print '<link rel="stylesheet" href="http://mima.c.fun.ac.jp/1012151/add_schedule.css">' + "\n"
  print '<script src="http://mima.c.fun.ac.jp/1012151/js/jquery.js"></script>' + "\n"
  print '<script src="http://mima.c.fun.ac.jp/1012151/js/jquery.datetimepicker.js"></script>' + "\n"
  print '<script src="http://mima.c.fun.ac.jp/1012151/js/build/jquery.datetimepicker.full.js"></script>' + "\n"
  print '<script language="JavaScript">' + "\n"
  print 'function mySubmit( place ) {' + "\n"
  print 'document.form1.allday.value = place;' + "\n"
  print 'document.form1.submit();' + "\n"
  print '}' + "\n"
  print '</script>' + "\n"
  print '</head>' + "\n"
  print '<body>' + "\n"
  print '<div id="layout">' + "\n"
  print '    <div align="center"><p>予定編集</p></div>' + "\n"
  print '    <br><br>' + "\n"
  print '<div id = "main" style="float:left;">' + "\n"
  print "<form action=\"add_schedule.rb? method=\"post\">" + "\n"
  print "<input type=\"hidden\" name=\"id\" value=\""
  print id
  print "\">"
  print ' <label>件名：</label>' + "\n"
  print "<input type=\"text\" name=\"content\" size=\"20\" value=\""
  print $title
  print '"><br>' + "\n"
  print '<label>開始：</label>' + "\n"
  print '<input id="s_day" type="text" name="s_day">' + "\n"
  print '<input id="s_time" type="text" name="s_time">' + "\n"
  print '<br><label>終了：</label>' + "\n"
  print '<input id="e_day" type="text" name="e_day">' + "\n"
  print '<input id="e_time" type="text" name="e_time">' + "\n"
  print '<p><label>カテゴリ：</label>'
  print '<select name="category">'
  num = 0
  db.execute('select * from category where s=?', '1') do |_row|
    num += 1
  end
  c_name = Array.new(num)
  i = 0
  db.execute('select * from category where s=?', '1') do |row|
    c_name[i] = row[0]
    if c_name[i] == $cate
      print "<option value=\"#{c_name[i].to_s.chomp}\" selected>#{c_name[i].to_s.chomp}</option>"
    else
      print "<option value=\"#{c_name[i].to_s.chomp}\">#{c_name[i].to_s.chomp}</option>"
      end
    i += 1
  end
  print "<option value=\"no_name\">新規作成</option></select></p>"
  print '<p><input type="submit" value="OK"  onclick="window.close()" class="btn"></p>' + "\n"
  print '</form>' + "\n"
  print '</div>' + "\n"
  # print '  <div id="allday" style="float:right;">' + "\n"
  # print '  <FORM name="form1" action="add_schedule.rb" onSubmit="return false">' + "\n"
  # print '  <INPUT type="hidden" name="allday" value="">' + "\n"
  # print '  <INPUT type="checkbox" onClick="mySubmit(\'all\')">終日' + "\n"
  # print '  </FORM>' + "\n"
  # print '  </div>' + "\n"
  print '  <br>' + "\n"
  print "<div id = \"buttom\" align=\"right\" style=\"clear:both;\"></div>"
  print "<form action=\"add_schedule.rb"
  print "\" method=\"post\">\n "
  print "<input type=\"hidden\" name=\"del\" value=\""
  print id
  print "\">"
  print "<input type=\"submit\" value=\"削除\"  onclick=\"window.close()\" class=\"btn\">"
  print '</form>'
  print '</div>'
  print "\n"
  print '' + "\n"
  print '</body>' + "\n"
  print '<script>' + "\n"
  print '/*' + "\n"
  print 'window.onerror = function(errorMsg) {' + "\n"
  print '	$(\'#console\').html($(\'#console\').html()+\'<br>\'+errorMsg)' + "\n"
  print '}*/' + "\n"
  print '' + "\n"
  print '$.datetimepicker.setLocale(\'ja\');' + "\n"
  print '$(\'#datetimepicker_format\').datetimepicker({value:\'2015/04/15 05:03\', format: $("#datetimepicker_format_value").val()});' + "\n"
  print '$("#datetimepicker_format_change").on("click", function(e){' + "\n"
  print '	$("#datetimepicker_format").data(\'xdsoft_datetimepicker\').setOptions({format: $("#datetimepicker_format_value").val()});' + "\n"
  print '});' + "\n"
  print '$("#datetimepicker_format_locale").on("change", function(e){' + "\n"
  print '	$.datetimepicker.setLocale($(e.currentTarget).val());' + "\n"
  print '});' + "\n"
  print '' + "\n"
  print '$(\'#datetimepicker\').datetimepicker({' + "\n"
  print 'dayOfWeekStart : 1,' + "\n"
  print 'lang:\'ja\',' + "\n"
  print 'disabledDates:[\'1986/01/08\',\'1986/01/09\',\'1986/01/10\'],' + "\n"
  print 'startDate:	\'1986/01/05\'' + "\n"
  print '});' + "\n"
  print '$(\'#datetimepicker\').datetimepicker({value:\'2015/04/15 05:03\',step:10});' + "\n"
  print '$(\'.some_class\').datetimepicker();' + "\n"
  print '$(\'#datetimepicker_mask\').datetimepicker({' + "\n"
  print '	mask:\'9999/19/39 29:59\'' + "\n"
  print '});' + "\n"
  print '$(\'#s_time\').datetimepicker({' + "\n"
  print '	datepicker:false,' + "\n"
  print '	format:\'H:i\',' + "\n"
  print '	value: \''
  print $s_time
  print "'," + "\n"
  print '	step:5' + "\n"
  print '});' + "\n"
  print '$(\'#s_day\').datetimepicker({' + "\n"
  print '	lang:\'jp\',' + "\n"
  print '	timepicker:false,' + "\n"
  print '	value: \''
  print $s_day
  print "'," + "\n"
  print ' format:\'Y-m-d\',' + "\n"
  print '	formatDate:\'Y/m/d\',' + "\n"
  print '});' + "\n"
  print '$(\'#e_time\').datetimepicker({' + "\n"
  print '	datepicker:false,' + "\n"
  print '	format:\'H:i\',' + "\n"
  print '	value: \''
  print $e_time
  print "'," + "\n"
  print '	step:5' + "\n"
  print '});' + "\n"
  print '$(\'#e_day\').datetimepicker({' + "\n"
  print '	lang:\'jp\',' + "\n"
  print '	timepicker:false,' + "\n"
  print '	value: \''
  print $e_day
  print "'," + "\n"
  print '	format:\'Y-m-d\',' + "\n"
  print '	formatDate:\'Y/m/d\',' + "\n"
  print '});' + "\n"

  print '$(\'#datetimepicker3\').datetimepicker({' + "\n"
  print '	inline:true' + "\n"
  print '});' + "\n"
  print '$(\'#datetimepicker4\').datetimepicker();' + "\n"
  print '$(\'#open\').click(function(){' + "\n"
  print '	$(\'#datetimepicker4\').datetimepicker(\'show\');' + "\n"
  print '});' + "\n"
  print '$(\'#close\').click(function(){' + "\n"
  print '	$(\'#datetimepicker4\').datetimepicker(\'hide\');' + "\n"
  print '});' + "\n"
  print '$(\'#reset\').click(function(){' + "\n"
  print '	$(\'#datetimepicker4\').datetimepicker(\'reset\'); ' + "\n"
  print '});' + "\n"
  print 'var dateToDisable = new Date();' + "\n"
  print '	dateToDisable.setDate(dateToDisable.getDate() + 2);' + "\n"
  print '$(\'#datetimepicker11\').datetimepicker({' + "\n"
  print '	beforeShowDay: function(date) {' + "\n"
  print '		if (date.getMonth() == dateToDisable.getMonth() && date.getDate() == dateToDisable.getDate()) {' + "\n"
  print '			return [false, ""]' + "\n"
  print '		}' + "\n"
  print '' + "\n"
  print '		return [true, ""];' + "\n"
  print '	}' + "\n"
  print '});' + "\n"
  print '' + "\n"
  print '$(\'#datetimepicker_dark\').datetimepicker({theme:\'dark\'})' + "\n"
  print '' + "\n"
  print '' + "\n"
  print '' + "\n"
  print '</script>' + "\n"
  print '</html>' + "\n"
end
db.close
