#!/usr/bin/ruby
# coding: utf-8
require 'cgi'
require 'date'
require 'sqlite3'
require 'kconv'
data = CGI.new
print "Content-type: text/html\n\n"
 per = data['val']
 db = SQLite3::Database.new('scheduler.db')
  db.results_as_hash = true
  db.execute('update par set num =?', per)
db.close
