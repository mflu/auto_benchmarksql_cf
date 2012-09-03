# Copyright (c) 2009-2011 VMware, Inc.
require 'rubygems'
require 'bundler/setup'
require 'rye'
nodes_file=ARGV[0]
exit(1) unless nodes_file
user=ARGV[1]
passwd=ARGV[2]
exit(1) unless user && passwd
cmd=ARGV[3]
exit(1) unless cmd
args=ARGV.slice(4, ARGV.size-1)
if File.exist?(nodes_file)
  nodes=`cat #{nodes_file}`.split("\n")
else
  nodes=[nodes_file]
end

rset = Rye::Set.new('default', :user=> user, :password => passwd, :parallel => true, :safe => false)
nodes.each do |node|
  rset.add_box(node)
end
puts rset.send(cmd.to_sym, args)
