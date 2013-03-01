# Copyright (c) 2009-2013 VMware, Inc.
require "rubygems"
require "bundler/setup"

require 'optparse'

$:.unshift(File.expand_path("../../lib", __FILE__))

require "harness"

def parse_m(str, key_symbol=false)
  h = {}
  str.split(",").each do |x|
    k, v = x.split(':')
    key = key_symbol ? k.to_sym : k
    h[key] = v
  end
  h
end

config = {'admin' => {}}

user_number = 0
default_password = "password"
push_app = false
push_app_m = {}
service_m = {}
total_service_inst_num = 0
avg_num_per_user = 16


optparse = OptionParser.new do|opts|
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end

  opts.on('-t', '--target TARGET', String, 'target url') do |target|
    config['target'] = target
  end

  opts.on('-s', '--secret SECRET', String, 'uaa_cc_client_secret') do |secret|
    config['uaa_cc_secret'] = secret
  end

  opts.on('-e', '--email ADMIN_EMAIL', String, 'admin email') do |a_email|
    config['admin']['email'] = a_email
  end

  opts.on('-p', '--password ADMIN_PASSWORD', String, 'admin password') do |a_passwd|
    config['admin']['passwd'] = a_passwd
  end

  opts.on('-d', '--dpass DEFAULT_PASSWORD', String, 'default password for created users') do |d_passwd|
    default_password = d_passwd
  end

  opts.on('-w', '--namespace NAMESPACE', String, 'namespace and username prefix') do |ns|
    config['namespace'] = ns
  end

  opts.on('-x', '--push', 'whenther to push an application') do
    push_app = true
  end

  opts.on('-a', '--app APP_MANIFEST', String, 'application manifest') do |str|
    puts str
    push_app_m = parse_m(str)
  end

  opts.on('-i', '--service SERVICE_MANIFEST', String, 'service manifest') do |str|
    service_m = parse_m(str, true)
  end

  opts.on('-n', '--instnum INST_NUM', Numeric, 'number of service instances for all users') do |num|
    total_service_inst_num = num.to_i
  end

end


begin
  optparse.parse!

  user_num = total_service_inst_num/avg_num_per_user + (total_service_inst_num % avg_num_per_user == 0 ? 0 : 1)

  users = []
  remain_num = total_service_inst_num

  CF::Harness::HarnessHelper.set_config(config)
  user_num.times do |i|
    user = {"email" => "#{config['namespace']}#{i}@vmware.com", "passwd" => "#{default_password}"}
    CF::Harness::HarnessHelper.create_users([user])

    app_name = "#{config['namespace']}_app#{i}"
    push_app_m['no_start'] = true
    push_app_m['name'] = app_name

    app = CF::Harness::HarnessHelper.create_push_app(user, app_name, push_app_m, :update_app_if_exist => false, :check_start => false) if push_app
    sleep 2
    service_num = remain_num >= avg_num_per_user ? avg_num_per_user : remain_num
    service_num.times do |t|
      service_name = "#{app_name}_service#{t}"
      service_m[:name] = service_name
      CF::Harness::HarnessHelper.create_bind_service(user, app, service_name, service_m, :bind => push_app, :restart_app => false)
    end
    remain_num = total_service_inst_num - avg_num_per_user
  end
rescue => e
  puts "error: #{e} #{e.backtrace.join('|')}"
end
