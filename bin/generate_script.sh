#!/bin/bash
bin_dir=`dirname $0`
source $bin_dir/../config/common

idx=0
for inst_type in heavy medium light idle
do
  echo "Generate script file for instances with type: ${inst_type}"
  inst_type_var_name="inst_${inst_type}"
  for i in `seq 1 ${!inst_type_var_name}`
  do
    script_file=$base_dir/var/$local_script_dir/${service_type}.${inst_num}.${inst_type}.$i
    $base_dir/deploy/script_generator.sh $idx $script_file "${inst_type}"
    let idx++
  done
done

#for i in `seq 1 $inst_medium`
#do
#  script_file=$base_dir/var/$local_script_dir/${service_type}.${inst_num}.medium.$i
#  $base_dir/deploy/script_generator.sh $idx $script_file  "medium"
#  let idx++
#done

#for i in `seq 1 $inst_light`
#do
#  script_file=$base_dir/var/$local_script_dir/${service_type}.${inst_num}.light.$i
#  $base_dir/deploy/script_generator.sh $idx $script_file  "light"
#  let idx++
#done
