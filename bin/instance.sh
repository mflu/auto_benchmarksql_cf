#!/bin/bash
bin_dir=`dirname $0`
source $bin_dir/../config/common

avg_num=16
echo "start to create worker..."
((number_of_users=inst_num/avg_num + 1))
number_of_svc=$inst_num
for i in `seq 1 $number_of_users`; do
  vmc login --email $admin_user --passwd $admin_pass
  token="$token_dir/perform_instance_$i.token"
  email="${user_prefix}_${service_type}_instance_${i}@vmware.com"
  log_file="$log_dir/perform_instance_$i.log"
  
  vmc add-user --email $email --passwd $user_passwd
  vmc login --email $email --passwd $user_passwd --token-file $token

  app_name="${service_type}_${user_prefix}_worker_${i}"
  vmc push $app_name --path $base_dir/assets/sinatra/app_sinatra_service  --mem 128 -n --token-file $token --no-start

  svc=0
  if (( number_of_svc >= avg_num ))
  then
    svc=$avg_num
  else
    svc=$number_of_svc
  fi
  for t in `seq 1 $svc`; do
    service_name="${service_type}_worker_service_${t}"
    ret=`vmc services | grep "$service_name |"`
    if test -z "$ret"
    then
      # you should use private vmc client https://github.com/andl/vmc
      vmc create-service $service_type $service_name -n --token-file $token --plan $service_plan --version $service_version --v1
      vmc bind-service $service_name $app_name --token-file $token
    fi
  done
  vmc stop $app_name --token-file $token
  ((number_of_svc=number_of_svc - svc))
done

# copy back the local db
ruby $base_dir/pkgs/rssh/rssh.rb $server_host  $server_user $server_password file_download $remote_db $local_db

