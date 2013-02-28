#!/bin/bash
bin_dir=`dirname $0`
source $bin_dir/../config/common

avg_num=16
((number_of_users=inst_num/avg_num + 1)) 
number_of_svc=$inst_num

echo "purge all the existing test user"
ruby $base_dir/pkgs/cfharness/bin/cleanup.rb -t $target_url -s $uaa_cc_secret -e $admin_user -p $admin_pass -w "${user_prefix}_${service_type}_user" -n $number_of_users -d $user_passwd

vmc target $target_url
echo 1 | vmc login --email $admin_user --password $admin_pass

for user in `vmc users | grep $user_prefix | awk '{print $1}'`; do
  for inst in `vmc services -u $user`; do
     vmc delete-service $inst -u $user -f 
  done

  vmc delete-user $user -f;
done

rm -rf $base_dir/var/${service_type}_node.db
