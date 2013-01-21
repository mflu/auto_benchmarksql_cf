require 'mysql2'
require 'pg'
require 'logger'
#how to use
#ruby load.rb mysql 10.42.134.31 3307 user_a passwd_a database_name idle_data_size
DEFAULT_SIZE = 8 * 1024 * 1024 # 8MB
props_file, warehouse, scale_factor, log_file = ARGV

def create_data_with_size(size)
  b = size
  c = ('a'..'z').to_a + ('A'..'Z').to_a
  (1..b).map { c[rand(c.size)] }.join
end

def parse_props(props_file)
  props={}
  File.open(props_file, 'r') do |f|
    f.lines.each do |line|
      tmp=line.split("=")
      if tmp && tmp.count == 2
        props[tmp[0]] = tmp[1].strip
      end
    end
  end
  conn = props["conn"]
  match_res = /jdbc:(.*):\/\/(.*):(.*)\/(.*)/.match(conn)
  props["service_type"] = match_res[1]
  props["host"] = match_res[2]
  props["port"] = match_res[3]
  props["database"] = match_res[4]
  props
end

if log_file
logger = Logger.new(log_file)
else
logger = Logger.new(STDOUT)
end
logger.level = Logger::DEBUG
props = parse_props(props_file)
service_type, host, port, user, password, database = %w[service_type host port user password database].map { |key| props[key] }

logger.info("loading to idle instnace using props #{props.inspect}")
# should calculate the database size according to the warehouse and
total_size = (warehouse.to_f * scale_factor.to_f * 100* 1024 * 1024).to_i
logger.info("will load #{total_size} bytes to instance")
client = nil
begin
  case service_type
  when "mysql"
    client = Mysql2::Client.new(:host => host, :username => user, :port => port.to_i, :password => password, :database => database)
    client.query("Create table IF NOT EXISTS idle_data (data_value longtext)")
    client.query("truncate table idle_data")
  when "postgresql" # pg
    client = PGconn.open(host, port, :dbname => database, :user => user, :password => password)
    client.query("create table idle_data (data_value text)") if client.query("select * from pg_catalog.pg_class where relname = 'idle_data';").num_tuples() < 1
    client.query("truncate idle_data")
  end
  
  sleep 2
  logger.info("start to load to idle instance")
  (total_size / DEFAULT_SIZE).times do
    client.query("insert into idle_data values ('#{create_data_with_size(DEFAULT_SIZE)}')")
  end
  left_size = total_size % DEFAULT_SIZE
  client.query("insert into idle_data values ('#{create_data_with_size(left_size)}')") if left_size > 0
  logger.info("successfully loading to idle instance")
rescue => e
  logger.error("fail to load to idle instance for #{e.inspect}: #{e.backtrace.join('|')}")
ensure
  client.close if client
end
