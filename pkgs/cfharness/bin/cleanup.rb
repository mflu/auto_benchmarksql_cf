# Copyright (c) 2009-2013 VMware, Inc.
require "rubygems"
require "bundler/setup"

require 'optparse'

$:.unshift(File.expand_path("../../lib", __FILE__))

require "harness"

config = {'admin' => {}}

user_number = 0
default_password = "password"
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
    CF::Harness::HarnessHelper.cleanup!([user])
    remain_num = total_service_inst_num - avg_num_per_user
  end
rescue => e
  puts "error: #{e} #{e.backtrace.join('|')}"
end
