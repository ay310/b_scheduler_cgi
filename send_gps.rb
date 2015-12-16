#!/usr/bin/ruby
# coding: utf-8
require 'cgi'
require 'date'
require 'sqlite3'
require 'kconv'
data = CGI.new
print "Content-type: text/html\n\n"
#indexから送られてくるやつ
location = data['gps']
#て入力した位置情報から送られてくるやつ
add_location = data['addlocation']
d = Time.now

class Array
  def count
    k = Hash.new(0)
    self.each{|x| k[x] += 1 }
    return k
  end
end

def chday(day)
  day = '0' + day.to_s if day.to_s.length == 1
  day
end

def to_min(time)
  if time == '00:00'
    return 0
  else
    arytime = time.split(':')
    return arytime[0].to_i * 60 + arytime[1].to_i
  end
end

def define_gps(gps)
  #gpsを指定桁取得して変換する(現在は6桁ずつ)
  return nil if gps==""
  location = gps.split(',')
  lat=location[0]
  lng=location[1]
  lat = lat.split("")
  lng=lng.split("")
  gps = lat[0].to_s+lat[1].to_s+lat[2].to_s+lat[3].to_s+lat[4].to_s+lat[5].to_s+","+lng[0].to_s+lng[1].to_s+lng[2].to_s+lng[3].to_s+lng[4].to_s+lng[5].to_s
  return gps
end

def same_location(gps)
  #現在地が位置dbと一致しているものがあるか確認
  #６回
  return nil if gps==""
  location = gps.split(',')
  lat=location[0]
  lng=location[1]
  lat = lat.split("")
  lng=lng.split("")
  db = SQLite3::Database.new('scheduler.db')
  $num=0
  db.execute('select * from location') do |row|
    $num += 1
  end
  $name = Array.new($num)
  $db_gps = Array.new($num)
  i = 0
  db.execute('select * from location') do |row|
    $name[i] = row[1].to_s.toutf8
    $db_gps[i] = row[2].to_s.toutf8
    i += 1
  end
    db.close
    for i in 0.. $num.to_i-1
      db_location=$db_gps[i].split(",")
      db_lat=db_location[0]
      db_lng=db_location[1]
      db_lat = db_lat.split("")
      db_lng=db_lng.split("")
      same=0
      for j in 0.. 5
        if lat[j]==db_lat[j] && lng[j]==db_lng[j]
          same =same+1
        end
      end
      if same>=5
        return $name[i].to_s
      end
    end
    return nil
  end

  def add_db_log(s_name, s_category, location_name)
    if s_name==""
    else
      db = SQLite3::Database.new('scheduler.db')
        db.execute('insert into log(name, location, category, week, time) values(?, ?, ?, ?, ?)', s_name, location_name, s_category, $week, $get_time)
      db.close
    end
  end

def search_schedule(today, t, location_name)
  #現在スケジュールが入っていた場合、そこに位置を記録する
  db = SQLite3::Database.new('scheduler.db')
  db.results_as_hash = true
    min = Array.new(1339, '0')
    num=0
    db.execute('select * from schedule where s_day=?', today) do |row|
      #今日の1440分を0でうめ、予定がある分はスケジュールのidを埋め込む
      st=to_min(row[3]).to_i
      et=to_min(row[5]).to_i
      id=row[0].to_i
      for i in st.to_i ..et.to_i
        min[i]=id
      end
    end
    n=0
      puts min[to_min(t).to_i]
      if min[to_min(t).to_i]!=0
        db.execute('update schedule set location = ? where id=?', location_name, min[to_min(t).to_i])
        db.execute('select * from schedule where id=?', min[to_min(t).to_i]) do |row|
          $s_name=row[1].to_s
          $s_category=row[6].to_s
        end
        add_db_log($s_name, $s_category, location_name)
        #TABLE:log に　スケジュール名、カテゴリ、位置名、曜日、時刻を追加する
      end
  db.close
end

def add_db_categorylocation
  puts "call add_db_categorylocation!\n"
  db = SQLite3::Database.new('scheduler.db')
  db.results_as_hash = true
  #↓カテゴリの個数を取得
  c_num=0
  db.execute('select * from category') do |row|
    c_num=c_num+1
  end
  c_name=Array.new(c_num)
  c_location=Array.new(c_num)
  i=0
  #↓配列にカテゴリ名を格納
  db.execute('select * from category') do |row|
    c_name[i]=row[0]
    i=i+1
  end
  #↓TABLE:logから特定のカテゴリ名を探す
  printf("c_num:%s\n", c_num)
  for j in 1..c_num.to_i-1
    p j
    db.execute('select * from log where category=?', c_name[j]) do |row|
      if c_location[j]==""
        c_location[j]=row[1]
      else
        c_location[j]=c_location[j].to_s+","+row[1].to_s
      end
    end
    printf("c_name[%s]:%s\n",j, c_name[j])
    printf("c_location[%s]:%s\n",j, c_location[j])
    if c_location[j].to_s!=""
    add_db_c_location(c_name[j], c_location[j])
    end
  end
  db.close
end

def add_db_c_location(category, location)
    puts "call add_db_c_location!\n"
    printf("category:%s, location:%s\n",category,location)
  #categoryにカテゴリ名、locationにカンマ区切りの位置名が入ってる
  loca = location.split(',')
  num = loca.count
  db = SQLite3::Database.new('scheduler.db')
  db.results_as_hash = true
  #↓位置名の個数を取得
  l_num=0
  db.execute('select * from location') do |row|
    l_num=l_num+1
  end
  l_name=Array.new(l_num)
  i=0
#↓配列に位置名を格納
  db.execute('select * from location') do |row|
    l_name[i]=row[1]
    i=i+1
  end
  #items = Locate_events.new
  #items=loca.count
  #puts items
loca.inject(count=Hash.new(0)){|hash, a| hash[a] += 1; hash}
search_max=""
for i in 0..l_num.to_i-1
if search_max==""
  search_max= count[l_name[i]]
else
  search_max=search_max.to_s+","+count[l_name[i]].to_s
end
end
 max=search_max.split(',')
 p maxvalue=max.max

 new_location=count.key(maxvalue.to_i)
#new_locationが最も参照回数が多かった位置情報
  db.execute('update category set location = ? where name=?', new_location, category)

  db.close
end

db = SQLite3::Database.new('scheduler.db')
  db.results_as_hash = true
  db.execute('select * from gps order by day desc, time desc limit 1') do |row|
    $gps=row[2].to_s
    $lastday=row[3].to_s
    $lasttime=row[4].to_s
  end
db.close

today = d.year.to_s + '-' + chday(d.month).to_s + '-' + chday(d.day).to_s
$get_time = chday(d.hour).to_s+":"+chday(d.min).to_s
$week=d.wday

location_name=same_location(location)
search_schedule(today, $get_time, location_name)

if location!=""
  #indexから来た時
  if $lastday.to_s==today.to_s && (to_min($get_time).to_i-to_min($lasttime).to_i) <10
    #10分
    #p "same"
  else
    #p "not_same"
    puts "gpsを追加"
    db = SQLite3::Database.new('scheduler.db')
    db.execute('insert into gps  (name, position, day, time) values(?, ?, ?, ?)', location_name, location, today, $get_time)
    db.close
  end
   add_db_categorylocation
elsif add_location!=""
  db = SQLite3::Database.new('scheduler.db')
  db.execute('insert into gps  (name, position, day, time) values(?, ?, ?, ?)', add_location, $gps, today, $get_time)
  new_gps=define_gps($gps)
  db.execute('insert into location  (name, gps) values(?, ?)', add_location, new_gps)
  db.close
end
print '<html>'
print '<head><META http-equiv="refresh"; content="0; URL=index.rb"></head><body></body></html>'
