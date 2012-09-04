#!/bin/bash
base_dir=`dirname $0`
source $base_dir/config/common
time_dir=`date +%s`
mkdir -p $base_dir/logs/$time_dir
for ch in `cat $base_dir/var/client_list`
do
ruby $base_dir/pkgs/rssh/rssh.rb $ch $client_user $client_password tar czvf $remote_base_dir/$ch.logs.tar.gz $remote_log_dir
ruby $base_dir/pkgs/rssh/rssh.rb $ch $client_user $client_password file_download $remote_base_dir/$ch.logs.tar.gz $base_dir/logs/$time_dir
done
