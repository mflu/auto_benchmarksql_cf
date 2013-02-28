# Copyright (c) 2009-2013 VMware, Inc.
require "rubygems"
require "bundler/setup"

require 'optparse'

$:.unshift(File.expand_path("../../lib", __FILE__))

require "harness"

config = {'admin' => {}}

parallel_user_number = 0
default_password = "password"

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

  opts.on('-w', '--namespace NAMESPACE', String,'namespace and username prefix') do |ns|
    config['namespace'] = ns
  end

  opts.on('-n', '--num [NUM]', Numeric,'number of users') do |num|
    parallel_user_number = num.to_i || 0
  end
end


begin
  optparse.parse!

  puts config
  #exit

  #example: -t ccng.cf152.dev.las01.vcsops.com -s fOZF5DMNDZIfCb9A -e sre@vmware.com -p the_admin_pw -w testharnesslib -n 5
  #target = "ccng.cf152.dev.las01.vcsops.com"
  #uaa_cc_client_secret = "fOZF5DMNDZIfCb9A"
  #admin_email = "sre@vmware.com"
  #admin_passwd = "the_admin_pw"
  #namespace = "testharnesslib"

  users = []
  parallel_user_number.times do |i|
    users << {"email" => "#{config['namespace']}#{i+1}-harness_test@vmware.com", "passwd" => "#{default_password}"}
  end

  CF::Harness::HarnessHelper.set_config(config)

  CF::Harness::HarnessHelper.cleanup!(users)
rescue => e
  puts "error: #{e} #{e.backtrace.join('|')}"
end
