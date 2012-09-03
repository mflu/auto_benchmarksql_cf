#!/bin/bash
base_dir=`dirname $0`
export PATH=$base_dir/bssh:$PATH

source $base_dir/config/driver
source $base_dir/config/$driver_name/config

source $base_dir/config/client

for client in `cat $base_dir/config/client_nodes | head -n $client_num`
do
  # don't use -r option here
  bssh -p $client_password $client_user@$client "ls /"
done

tmp_tt2_conf="/tmp/deploy.$RANDOM.conf"
echo "user=$client_user" > $tmp_tt2_conf
echo "passwd=$client_password" >> $tmp_tt2_conf
#echo "rootpasswd=$client_rootpassword" >> $tmp_tt2_conf
echo "port=22" >> $tmp_tt2_conf
cat $base_dir/config/client_nodes | head -n $client_num >> $tmp_tt2_conf
$base_dir/bssh/tt2 -f $tmp_tt2_conf -p $base_dir/bssh/parser "ls /"
#cat $tmp_tt2_conf
echo $?
rm -rf $tmp_tt2_conf
