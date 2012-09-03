#!/bin/bash
base_dir=`dirname $0`
source $base_dir/config/common
action=$1
if test ! -z "$action"
then
  echo "Execute action: $action"
  for ch in `cat $base_dir/config/client_nodes | grep -v '^$' | head -n $client_num`
  do
    action_script="$remote_base_dir/${action}.sh"
    ruby $base_dir/pkgs/rssh/rssh.rb $ch $client_user $client_password chmod +x $action_script
    ruby $base_dir/pkgs/rssh/rssh.rb $ch $client_user $client_password ls -la $action_script
    ruby $base_dir/pkgs/rssh/rssh.rb $ch $client_user $client_password chmod +x $remote_script_dir/*.sh
    ruby $base_dir/pkgs/rssh/rssh.rb $ch $client_user $client_password /bin/bash $action_script
  done
  if test $action = "benchmark"
  then
    sleep_time=$((load_time * 60))
    echo "Will sleep $sleep_time seconds to wait action to finish"
    sleep $sleep_time
  fi
else
  echo "Usage: run.sh prepare|preload|benchmark|stop"
fi

