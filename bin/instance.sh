#!/bin/bash
bin_dir=`dirname $0`
source $bin_dir/../config/common

vmc target $target_url

avg_num=16
echo "start to create worker..."
((number_of_users=inst_num/avg_num + 1))
number_of_svc=$inst_num

# create test users
ruby $base_dir/pkgs/cfharness/bin/create_users.rb -t $target_url -s $uaa_cc_secret -e $admin_user -p $admin_pass -w "${user_prefix}_${service_type}_instance" -n $number_of_users -d $user_passwd

for i in `seq 1 $number_of_users`; do
  echo 1 | vmc login --email $admin_user --password $admin_pass
  email="${user_prefix}_${service_type}_instance_${i}@vmware.com"
  log_file="$log_dir/perform_instance_$i.log"

  app_name="${service_type}_${user_prefix}_worker_${i}"
  if test $use_default_user -eq 0
  then
    echo no | vmc push --name $app_name --path $base_dir/assets/sinatra/app_sinatra_service  --memory 128 --instances 1 -u $email -f --no-start --framework sinatra --runtime ruby19 --host "$app_name.$suggest_url"
  fi

  svc=0
  if (( number_of_svc >= avg_num ))
  then
    svc=$avg_num
  else
    svc=$number_of_svc
  fi
  for t in `seq 1 $svc`; do
    service_name="${service_type}_worker_service_${t}"
    ret=`vmc services -u $email | grep "$service_name"`
    if test -z "$ret"
    then
      vmc create-service --offering $service_type --name $service_name -u $email --plan $service_plan --version $service_version
      if test $use_default_user -eq 0
      then
        vmc bind-service $service_name $app_name -u $email
      fi
    fi
  done
  if test $use_default_user -eq 0
  then
    vmc stop $app_name -u $email
  fi
  ((number_of_svc=number_of_svc - svc))
done

# copy back the local db
ruby $base_dir/pkgs/rssh/rssh.rb $server_host  $server_user $server_password file_download $remote_db $local_db

