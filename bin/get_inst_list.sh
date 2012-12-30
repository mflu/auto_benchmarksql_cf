#!/bin/bash
service_type=$1
if test -z "$service_type"
then
  service_type=postgresql
fi

inst_type=$2
if test -z "$inst_type"
then
  inst_type=idle
fi

cur_dir=`dirname $0`

inst_file=$cur_dir/../var/inst_list.${service_type}.${inst_type}

rm -rf $inst_file

for f in `ls $cur_dir/../var/props/$service_type.*.$inst_type.*`
do
  service_id=`cat $f | grep jdbc | awk -F'/' '{print $4}'`
  echo $service_id >> $inst_file
done
