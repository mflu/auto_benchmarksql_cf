#!/usr/bin/env ruby
require 'rubygems'
#require 'pry'
#require 'pry-nav'
#require 'pry-stack_explorer'
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
  inst=`sqlite3 #{local_db} "select name,'5432', plan from vcap_services_postgresql_node_provisionedservices limit 1 offset #{index}"`
else
  inst=`sqlite3 #{local_db} "select name,port,plan from vcap_services_postgresql_node_wardenprovisionedservices limit 1 offset #{index}"`
end
#binding.pry
inst_name, port, plan=inst.split('|')

if wardenized == 0
  bind_line=`sqlite3 #{local_db} "select user, password, default_user from vcap_services_postgresql_node_bindusers where provisionedservice_name = '#{inst_name}' and default_user = 'f' limit 1"`
else
  bind_line=`sqlite3 #{local_db} "select user, password, default_user from vcap_services_postgresql_node_wardenbindusers where wardenprovisionedservice_name = '#{inst_name}' and default_user = 'f' limit 1"`
end
user,password,default_user = bind_line.split('|')

content = "name=PostgreSQL\ndriver=org.postgresql.Driver\nconn=jdbc:postgresql://#{server_host}:#{port}/#{inst_name}\nuser=#{user}\npassword=#{password}\n"

File.open(prop_file, 'w') { |file| file.puts content }
else
  puts "local db file #{local_db} does not exist! "
  exit 1
end
