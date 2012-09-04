#!/bin/bash
base_dir=`dirname $0`
source $base_dir/config/common
log_dir=$1
log_time=$((load_time * 60))
cd $log_dir
rm -rf result.log
rm -rf result_sla.log
rm -rf result_tnx.log
rm -rf result_ct.log
rm -rf result_tmpc.log

echo "name,totalRT,avgRT,totalTnx,tnxW" result.log
for ch in `cat $base_dir/var/client_list`
do
  log_pak=$ch.logs.tar.gz
  rm -rf var
  tar xzvf $log_pak
  for i in `ls  var/vcap/data/logs/*.benchmark/report.txt`;do echo $i; cat $i;done | egrep 'Delivery|New-Order|Order-Status|Payment|Stock-Level'  | grep -v : >> result.log
  
  for i in `ls  var/vcap/data/logs/*.benchmark/report.txt`;do echo $i; cat $i;done | egrep 'Delivery|New-Order|Order-Status|Payment|Stock-Level'  | grep : >> result_sla.log

  for i in `ls  var/vcap/data/logs/*.benchmark/report.txt`;do echo $i; cat $i;done | grep 'Total Tnx:' |awk -F: '{print $2}' >> result_tnx.log

  for i in `ls  var/vcap/data/logs/*.benchmark/report.txt`;do cat $i | tail -n 1;done |awk -F: '{print $1}' >> result_ct.log
  for i in `ls  var/vcap/data/logs/*.benchmark/report.txt`;do cat $i |tail -n 3 | head -n 1; done >> result_tmpc.log  
done
cat result.log | awk -v log_time=$log_time '{S[$1]+=$2}{C[$1]+=$4}{A=A+$4}{B=B+$2}END{for(a in S) print a,C[a]/A,S[a]/C[a],B/A,A/log_time}'
cat result_tnx.log | awk -v log_time=$log_time '{C=C+$1}END{print C/log_time}'
cat result_ct.log | awk '{C=C+1}{S=S+$1}END{print S/C}'
cat result_tmpc.log | awk '{S=S+$1}END{print S}'
cd -
