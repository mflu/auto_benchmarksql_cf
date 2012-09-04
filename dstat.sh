#!/bin/bash
  log_file=$1
  log_time=$2
  dstat -cdlmnpsy --disk-util --output $log_file 1 $log_time
