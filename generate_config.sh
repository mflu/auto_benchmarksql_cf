#!/bin/bash -x
base_dir=`dirname $0`

source $base_dir/config/common

idx=0
for i in `seq 1 $inst_heavy`
do
  prop_file=$base_dir/var/$local_prop_dir/${service_type}.${inst_num}.heavy.$i
  ruby $base_dir/deploy/config_generator/${service_type}/${service_type}.rb $local_db $idx $prop_file $service_wardenized $server_host
  let idx++
done

for i in `seq 1 $inst_medium`
do
  prop_file=$base_dir/var/$local_prop_dir/${service_type}.${inst_num}.medium.$i
  ruby $base_dir/deploy/config_generator/${service_type}/${service_type}.rb $local_db $idx $prop_file $service_wardenized $server_host
  let idx++
done

for i in `seq 1 $inst_light`
do
  prop_file=$base_dir/var/$local_prop_dir/${service_type}.${inst_num}.light.$i
  ruby $base_dir/deploy/config_generator/${service_type}/${service_type}.rb $local_db $idx $prop_file $service_wardenized $server_host
  let idx++
done


