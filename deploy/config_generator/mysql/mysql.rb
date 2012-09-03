#!/usr/bin/env ruby
require 'rubygems'
# local_db index prop_file wardenized
if ARGV.count < 5
  puts "Usage: local_db index prop_file wardenized server_host"
  exit 1
end
local_db=ARGV[0]
index=ARGV[1].to_i
prop_file=ARGV[2]
wardenized=ARGV[3].to_i
server_host=ARGV[4]

if File.exist?(local_db)
if wardenized == 0
  inst=`sqlite3 #{local_db} "select name,user,password,'3306',plan from vcap_services_mysql_node_provisioned_services limit 1 offset #{index}"`
else
  inst=`sqlite3 #{local_db} "select name,user,password,port,plan from vcap_services_mysql_node_warden_provisioned_services limit 1 offset #{index}"`
end

inst_name,user,password,port,plan=inst.split('|')

content = "name=MySQL\ndriver=com.mysql.jdbc.Driver\nconn=jdbc:mysql://#{server_host}:#{port}/#{inst_name}\nuser=#{user}\npassword=#{password}\n"

File.open(prop_file, 'w'){ |file| file.puts content }
else
  puts "Local db file #{local_db} does not exist!"
   exit 1
end
