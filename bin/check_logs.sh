#!/bin/bash
bin_dir=`dirname $0`
source $bin_dir/../config/common

action=$1

ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password ls "/var/vcap/data/logs/*$action.log| xargs tail -n 5; ifconfig eth0 | grep 'net addr' | awk -F: '{print \$2}' | awk '{print \$1}'"

