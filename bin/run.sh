#!/bin/bash
bin_dir=`dirname $0`
source $bin_dir/../config/common

action=$1
if test ! -z "$action"
then
  echo "Execute action: $action"
  for ch in `cat $base_dir/config/client_nodes | grep -v '^$' | head -n $client_num`
  do
    if test -e $base_dir/var/dist/$action/$ch -o $action = "stop"
    then
      action_script="$remote_base_dir/${action}.sh"
      ruby $base_dir/pkgs/rssh/rssh.rb $ch $client_user $client_password chmod "+x $action_script; ls -la $action_script; chmod +x $remote_script_dir/*.sh"
      ruby $base_dir/pkgs/rssh/rssh.rb $ch $client_user $client_password /bin/bash $action_script
    else
      echo "No action script for $ch"
    fi
  done
  if test $action = "benchmark"
  then
    sleep_time=$((load_time * 60))
    ruby $base_dir/pkgs/rssh/rssh.rb $server_host $server_user $server_password mkdir -p $remote_base_dir
    ruby $base_dir/pkgs/rssh/rssh.rb $server_host $server_user $server_password file_upload $base_dir/bin/dstat.sh $remote_base_dir/dstat.sh
    ruby $base_dir/pkgs/rssh/rssh.rb $server_host $server_user $server_password chmod +x $remote_base_dir/dstat.sh
    ruby $base_dir/pkgs/rssh/rssh.rb $server_host $server_user $server_password killall dstat
    ruby $base_dir/pkgs/rssh/rssh.rb $server_host $server_user $server_password rm -rf $remote_base_dir/dstat.log
    ruby $base_dir/pkgs/rssh/rssh.rb $server_host $server_user $server_password /bin/bash $remote_base_dir/dstat.sh $remote_base_dir/metric.log $sleep_time
    echo "Will sleep $sleep_time seconds to wait action to finish"
    sleep $sleep_time
    if test -z "$1"
      timestamp=`date +%s`
    else
      timestamp=$1
    fi
    ruby $base_dir/pkgs/rssh/rssh.rb $server_host $server_user $server_password file_download $remote_base_dir/metric.log.dstat $base_dir/dstat.$timestamp.csv
    ruby $base_dir/pkgs/rssh/rssh.rb $server_host $server_user $server_password file_download $remote_base_dir/metric.log.iostat $base_dir/iostat.$timestamp.csv
    $0 report
    $bin_dir/fetch_logs.sh $timestamp
    mkdir -p $base_dir/logs/$timestamp
    mv $base_dir/*.$timestamp.csv $base_dir/logs/$timestamp
  fi
else
  echo "Usage: run.sh prepare|preload|benchmark|report|stop"
fi

