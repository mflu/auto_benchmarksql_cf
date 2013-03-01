#!/bin/bash
bin_dir=`dirname $0`
source $bin_dir/../config/common

# create test users/apps/services

namespace=`echo ${user_prefix}_${service_type}_${service_plan}_${service_version} | sed s/\\\./_/g`
app_manifest="framework:sinatra,runtime:ruby19,memory:64,instances:1,path:${base_dir}/assets/sinatra/app_sinatra_service"
service_manifest="vendor:${service_type},version:${service_version},plan:${service_plan}"

if test "$use_default_user" = "0"
then
  will_push_app='-x'
fi

ruby $base_dir/pkgs/cfharness/bin/create_users.rb -t $target_url -s $uaa_cc_secret -e $admin_user -p $admin_pass -w "${namespace}_user" -n $inst_num -d $user_passwd $will_push_app -a $app_manifest -i $service_manifest

# copy back the local db
echo "copy back the local db file"
sed -i "/^$server_host /d" ~/.ssh/known_hosts
ruby $base_dir/pkgs/rssh/rssh.rb $server_host  $server_user $server_password file_download $remote_db $local_db
