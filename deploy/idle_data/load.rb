require 'mysql2'
require 'pg'
#how to use
#ruby load.rb mysql 10.42.134.31 3307 user_a passwd_a database_name idle_data_size

service_type, host, port, user, password, database, total_size = ARGV

def create_data_with_size(size)
  b = size * 1024 * 1024
  c = ('a'..'z').to_a + ('A'..'Z').to_a
  (1..b).map { c[rand(c.size)] }.join
end

client = nil

if service_type == "mysql"
  client = Mysql2::Client.new(:host => host, :user => user, :port => port, :password => password, :database => database)
  client.query("Create table IF NOT EXISTS idle_data (data_value text)")
else # pg
  client = PGconn.open(host, port, :dbname => database, :user => user, :password => password)
  client.query("create table idle_data (data_value text)") if client.query("select * from pg_catalog.pg_class where relname = 'idle_data';").num_tuples() < 1
end

DEFAULT_SIZE = 8
(total_size / DEFAULT_SIZE).times do
  client.query("insert into * idle_data values ('#{create_data_with_size(DEFAULT_SIZE)}')")
end
left_size = total_size % DEFAULT_SIZE
client.query("insert into * idle_data values ('#{create_data_with_size(left_size)}')") if left_size > 0
