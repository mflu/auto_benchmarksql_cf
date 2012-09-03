#!/bin/bash
base_dir=`dirname $0`

source $base_dir/config/common

idx=0
for i in `seq 1 $inst_heavy`
do
  script_file=$base_dir/var/$local_script_dir/${service_type}.${inst_num}.heavy.$i
  $base_dir/deploy/script_generator.sh $idx $script_file "heavy"
  let idx++
done

for i in `seq 1 $inst_medium`
do
  script_file=$base_dir/var/$local_script_dir/${service_type}.${inst_num}.medium.$i
  $base_dir/deploy/script_generator.sh $idx $script_file  "medium"
  let idx++
done

for i in `seq 1 $inst_light`
do
  script_file=$base_dir/var/$local_script_dir/${service_type}.${inst_num}.light.$i
  $base_dir/deploy/script_generator.sh $idx $script_file  "light"
  let idx++
done


