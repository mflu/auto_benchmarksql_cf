#!/bin/bash
  log_file=$1
  log_time=$2
  nohup dstat -cdlmnpsy --disk-util --output $log_file 1 $log_time 1>/dev/null 2>&1 &
