#!/bin/bash
bin_dir=`dirname $0`
source $bin_dir/../config/common

avg_num=16
((number_of_users=inst_num/avg_num + 1)) 
number_of_svc=$inst_num

namespace="${user_prefix}_${service_type}_${service_plan}_${service_version}"

echo "purge all the existing test user"
ruby $base_dir/pkgs/cfharness/bin/cleanup.rb -t $target_url -s $uaa_cc_secret -e $admin_user -p $admin_pass -w "${namespace}_user" -n $number_of_users -d $user_passwd

vmc target $target_url

for i in `seq 1 $number_of_users`; do
  email="${namespace}_user${i}-harness_test@vmware.com"

  pattern=`echo $email | sed s/\\\./_/g | sed s/@/_at_/g`

  org="${namespace}_usercfharness_test_org-$pattern"

  vmc login --email $admin_user --password $admin_pass --org $org

  for inst in `vmc services | grep ^${namespace}_app | awk '{print $1}'`; do
    vmc delete-service $inst -f
  done
done

echo "removing the local db file"
rm -rf $base_dir/var/${service_type}_node.db
