#!/bin/bash
bin_dir=`dirname $0`
source $bin_dir/../config/common

namespace=`echo ${user_prefix}_${service_type}_${service_plan}_${service_version} | sed s/\\\./_/g`

echo "purge all the existing test users's apps/services"
ruby $base_dir/pkgs/cfharness/bin/cleanup.rb -t $target_url -s $uaa_cc_secret -e $admin_user -p $admin_pass -w "${namespace}_user" -n $inst_num -d $user_passwd

echo "removing the local db file"
sed -i "/^$server_host /d" ~/.ssh/known_hosts
rm -rf $base_dir/var/${service_type}_node.db
