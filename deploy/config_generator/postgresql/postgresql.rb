#!/usr/bin/env ruby
require 'rubygems'
#require 'pry'
#require 'pry-nav'
#require 'pry-stack_explorer'
# local_db index prop_file wardenized
if ARGV.count < 7
  puts "Usage: local_db index prop_file wardenized server_host service_version use_default_user"
  exit 1 
end
local_db=ARGV[0]
index=ARGV[1].to_i
prop_file=ARGV[2]
wardenized=ARGV[3].to_i
server_host=ARGV[4]
service_version=ARGV[5]
use_default_user=ARGV[6].to_i

if File.exist?(local_db)
if wardenized == 0
  if service_version == "9.0"
    port = '5432'
  else
    port = '5433'
  end
  inst=`sqlite3 #{local_db} "select name, '#{port}', plan from vcap_services_postgresql_node_provisionedservices where version = '#{service_version}' limit 1 offset #{index}"`
else
  inst=`sqlite3 #{local_db} "select name,port,plan from vcap_services_postgresql_node_wardenprovisionedservices where version = '#{service_version}' limit 1 offset #{index}"`
end

inst_name, port, plan=inst.split('|')

default_user_flag = 'f'
if use_default_user == 1
  default_user_flag = 't'
end

if wardenized == 0
  bind_line=`sqlite3 #{local_db} "select user, password, default_user from vcap_services_postgresql_node_bindusers where provisionedservice_name = '#{inst_name}' and default_user = '#{default_user_flag}' limit 1"`
else
  bind_line=`sqlite3 #{local_db} "select user, password, default_user from vcap_services_postgresql_node_wardenbindusers where wardenprovisionedservice_name = '#{inst_name}' and default_user = '#{default_user_flag}' limit 1"`
end

user,password,default_user = bind_line.split('|')

content = "name=PostgreSQL\ndriver=org.postgresql.Driver\nconn=jdbc:postgresql://#{server_host}:#{port}/#{inst_name}\nuser=#{user}\npassword=#{password}\n"

File.open(prop_file, 'w') { |file| file.puts content }
else
  puts "local db file #{local_db} does not exist! "
  exit 1
end
