#!/bin/bash

base_dir=`dirname $0`
source $base_dir/config/common

vmc target $target_url
vmc login --email $admin_user --passwd $admin_pass

# purge all the existing users
for user in `vmc users | grep false | grep $user_prefix | awk '{print $2}'`; do
  yes | vmc delete-user $user;
done

rm -rf $base_dir/var/${service_type}_node.db
