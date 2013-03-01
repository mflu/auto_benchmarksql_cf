auto_benchmarksql_cf
====================

Scripts to drive [benchmarkSQL](https://github.com/andl/benchmarkSQL) to stress single postgresql/mysql service node.

## Install prerequisites ##
 + install dstat in your target service node: sudo apt-get install dstat
 + clone the code to local machine: git clone git://github.com/mflu/auto_benchmarksql_cf.git
 + install the specified vmc when using the v0.1 (see tags) which only works with legacy CC (v1) + services/services_ng
<pre><code>
   git clone git://github.com/andl/vmc.git
   gem build ./vmc.gemspec
   gem install ./gem install ./vmc-0.3.20.version.gem 
</code></pre>
 + OR, if you use v0.2+, you could just use latest vmc (optional)
<pre><code>
 gem install vmc --pre
</code></pre>
 + download and put jdk1.6.0_35.tar.gz under deploy directory
 + install rssh/benchmarkSQL/sqlite3
<pre><code>
  cd pkgs/rssh
  bundle install
  cd -
  cd pkgs/cfharness
  bundle install
  cd -
  sudo apt-get install -y maven
  git submodule update --init
  cd deploy/benchmarkSQL
  mvn package
  cd -
  sudo apt-get install -y sqlite3
</code></pre>

## Configurations ##
### All fields with #comment should be configured carefully.
+ common                            # will be included in all other scripts in bin
<pre><code>
  base_dir                          # the path of auto_benchmarksql_cf 
  platform=cloudfoundry
  source $base_dir/config/driver
  source $base_dir/config/client
  source $base_dir/config/server
  source $base_dir/config/$driver_name/config
  source $base_dir/config/cloudfoundry
</code></pre>

+ cloudfoundry                         # cloudfoundry deployment
<pre><code>
  suggest_url                          # deployment domain, such as cloudfoundry.com
  target_url="http://ccng.$suggest_url" # e.g. api.cloudfoundry.com

  admin_user                           # admin user
  admin_pass                           # admin password
  uaa_cc_secret                        # cc's client_secret of uaa

  service_type                         # service type: postgresql or mysql
  service_plan                         # service plan
  service_version                      # postgresql: 9.0 or 9.1 mysql: 5.1 or 5.5
  service_wardenized                   # whether use warden, 0 or 1 == false or true

  user_prefix                          # prefix of test user/app/service's name, any string
  user_passwd                          # test user's password

  use_default_user                     # 0 or 1, whether use the default user?, using non-default user, queries/transactions might be interrupted by long timer killer_

  log_dir=$base_dir/var/logs
  token_dir=$base_dir/var/tokens
  mkdir -p $log_dir
  mkdir -p $token_dir

  remote_db=/var/vcap/store/${service_type}_node.db
  local_db=$base_dir/var/${service_type}_node.db
</code></pre>
+ benchmarkSQL/config               # workload configuration
<pre><code>
  load_warehouse                    # benchmarkSQL -w
  load_scale_factor                 # benchmakrSQL -f
  load_delivery_weight              # benchmakrSQL -d
  load_cycle_time                   # benchmarkSQL -C (in ms)
  preload_data_to_idle              # whether to preload data to idle instance? 0 NO!
  load_time                         # time to run the benchmark (in minute)
  load_heavy                        # heavy load: how many concurrent connections to a heavy instance
  load_medium                       # medium load: how many concurrent connections to a medium instance
  load_light                        # light load: how many concurrent connections to a light instance
  load_idle=0
  inst_num                          # how many provisioned instances under test
  inst_heavy                        # how many instances under heavy load  (concurrent connections defined by load_heavy)
  inst_medium                       # how many instances under medium load (concurrent connections defined by load_medium)
  inst_light                        # how many instances under light load  (concurrent connections defined by load_light)
  inst_idle                         # how many instances keep idle status without any load
  local_prop_dir=props
  local_script_dir=scripts
  remote_base_dir=/var/vcap/data
  remote_prop_dir=$remote_base_dir/props
  remote_script_dir=$remote_base_dir/scripts
  remote_log_dir=$remote_base_dir/logs
  mkdir -p $base_dir/var/$local_prop_dir
  mkdir -p $base_dir/var/$local_script_dir
</code></pre>

+ client_nodes                        # list IPs of VMs to run benchmarkSQL
+ client:                             # client node number and user/password of client nodes
<pre><code>
  client_num                          # how many client nodes we will use
  client_user                         # VM's root user
  client_password                     # VM's root user's password
  client_rootpassword                 # duplicated
  deploy_driver                       # Whether to deploy benchmakrSQL to the client nodes? 0 NO!
  deploy_jdk                          # Whether to deploy JDK to the client nodes? 0 NO!
</code></pre>

+ driver                              # benchmarkSQL's infomation
<pre><code>
driver_name
driver_remote_in
jdk_dir                               # jdk tar package name (without tar.gz)
</code></pre>
+ server                              # target service node's ip address

## Run Benchmark ##
+ How to run benchmark
<pre><code>
  cd bin
  ./instance.sh                    # you could run cleanup.sh before to cleanup all provisioned instances)
  ./deploy.sh                      # deploy benchmarkSQL and JDK to client nodes
                                     # generate benchmark prop files and benchmark scripts of benchmarkSQL
  ./dispatch_load.sh               # copy prop files and benchmark scripts to client nodes
  ./run.sh prepare                 # recreate tables and indexes in all instances
                                     # non-blocking, you should use ./check_logs.sh prepare to check whether it is finished
  ./run.sh preload                 # preload data to instances
                                     # non-blocking, you should use ./check_logs.sh preload to check whether preloading is finished
  ./run.sh benchmark               # run the benchmark (blocking util the test is finished)
  ./run.sh report                  # generate report in each client node
  ./fetch_log.sh                   # fetch logs from client nodes, remember the timestamp
  ./parse_log.sh logs/$timestamp   # parse the log files to get the result report, the timestamp is generated by fetch_log.sh
</code></pre>
Tips: 
  - you could speficy the timestamp, the your could find your log files for this run in logs/$timestamp 
<pre><code>
   ./run.sh benchmark $timestamp
   ./fetch_log.sh $timestamp
   ./parse_logs.sh logs/$timestamp
</code></pre>
+ How to understand the result report
example:
<pre><code>
------------------------------------------------------------------------------
name         TnxWeight   TnxavgRT(ms)   GlobalAvgRT(ms)   Throughput(Tnx/sec)
Order-Status 0.039998    35.4091        78.0871           33.9183
Payment      0.432165    19.4486        78.0871           33.9183
Stock-Level  0.039015    99.4736        78.0871           33.9183
Delivery     0.0377377   137.784        78.0871           33.9183
New-Order    0.451083    131.207        78.0871           33.9183
33.9367
1009.31
911
-------------------------------------------------------------------------------
<code></pre>

  + 1st line is the header of the result.
  + 2nd line to 6th line:
<pre><code>
  ++ for each kind of transaction, 2nd column is the weight (ratio) of a transaction type, you could use this column to check whether the workload is a real TPCC workload.
  ++ for each kind of transaction, 3rd colum is the average response time (,s) of a transaction type. As you see, usually write-heavy operations (Delivery and New-Order) is time-consuming.
  ++ The 4th column is global weighted average response time (ms)
  ++ The 5th column is global throughput (tnx/sec)
<code></pre>
  + The last three lines are: GlobalThroughput(tnx/sec), AvgCycleTime(ms) and tpmC (new order transactions per minute).
  + Usually, we use global weighted average resposne time, throughput and tmpC as our benchmark result.
  + throughput ~ tmpC / 60 * 2 (if not, this is not a TPCC workload)
  + concurrency ~ throughput * AvgCycleTime /1000 (Little's Law), if specified concurrency > throughput * AvgCycleTime/1000, then client nodes meets bottleneck.
  + You could check the detailed result data in auto_benchmarksql_cf/logs/$timestamp and find the system metrics in dstat.log in the same directory, you could use the file to calculate the node's health value.
