#!/bin/bash
bin_dir=`dirname $0`
source $bin_dir/../config/common

cat $base_dir/config/client_nodes | grep -v '^$' | head -n $client_num > $base_dir/var/client_list

client_num=`cat $base_dir/var/client_list | wc -l`

if test $deploy_driver -eq 1
then
	ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password mv $driver_remote_in/$driver_name $driver_remote_in/$driver_name.bak
	ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password rm -rf $driver_remote_in/$driver_name.bak
	ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password dir_upload $driver_local_in/$driver_name $driver_remote_in
else  
	ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password ls -la $driver_remote_in/$driver_name
fi

ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password dir_upload $driver_local_in/idle_data $driver_remote_in
ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password chmod +x $driver_remote_in/idle_data/deploy.sh
ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password $driver_remote_in/idle_data/deploy.sh

if test $deploy_jdk -eq 1
then
        ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password mv $driver_remote_in/$jdk_dir $driver_remote_in/$jdk_dir.bak
        ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password rm -rf $driver_remote_in/$jdk_dir.bak
	ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password file_upload $driver_local_in/$jdk_dir.tar.gz $driver_remote_in
        ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password tar xzvf $driver_remote_in/$jdk_dir.tar.gz -C $driver_remote_in
        ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password $driver_remote_in/$jdk_dir/bin/java -version
else
        ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password $driver_remote_in/$jdk_dir/bin/java -version
fi

ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password rm -rf $remote_log_dir
ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password mkdir -p $remote_log_dir

rm -rf $base_dir/var/$local_prop_dir/*
rm -rf $base_dir/var/$local_script_dir/*
# syncup prop file
$base_dir/bin/generate_config.sh
ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password rm -rf $remote_prop_dir
ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password dir_upload $base_dir/var/$local_prop_dir $driver_remote_in
# syncup script file
$base_dir/bin/generate_script.sh
ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password rm -rf $remote_script_dir
ruby $base_dir/pkgs/rssh/rssh.rb $base_dir/var/client_list $client_user $client_password dir_upload $base_dir/var/$local_script_dir $driver_remote_in

