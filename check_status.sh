#!/bin/bash
base_dir=`dirname $0`
source $base_dir/config/common

ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password ps "xa | grep java |grep -v grep; ifconfig eth0 | grep 'net addr' | awk -F: '{print \$2}' | awk '{print \$1}'"

