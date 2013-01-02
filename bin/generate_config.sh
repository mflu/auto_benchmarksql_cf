#!/bin/bash -x
bin_dir=`dirname $0`
source $bin_dir/../config/common

idx=0

for inst_type in heavy medium light idle
do
  echo "Generate config file for instances with type: ${inst_type}"
  inst_type_var_name="inst_${inst_type}"
  for i in `seq 1 ${!inst_type_var_name}`
  do
    prop_file=$base_dir/var/$local_prop_dir/${service_type}.${inst_num}.${inst_type}.$i
    ruby $base_dir/deploy/config_generator/${service_type}/${service_type}.rb $local_db $idx $prop_file $service_wardenized $server_host $service_version $use_default_user
    let idx++
  done
done

#for i in `seq 1 $inst_medium`
#do
#  prop_file=$base_dir/var/$local_prop_dir/${service_type}.${inst_num}.medium.$i
#  ruby $base_dir/deploy/config_generator/${service_type}/${service_type}.rb $local_db $idx $prop_file $service_wardenized $server_host $servie_version
#  let idx++
#done

#for i in `seq 1 $inst_light`
#do
#  prop_file=$base_dir/var/$local_prop_dir/${service_type}.${inst_num}.light.$i
#  ruby $base_dir/deploy/config_generator/${service_type}/${service_type}.rb $local_db $idx $prop_file $service_wardenized $server_host $service_version
#  let idx++
#done
