auto_benchmarksql_cf
====================

Scripts to drive benchmarkSQL to stress single postgresql/mysql service node.

## Install prerequisites ##
 + install dstat in your target service node: sudo apt-get install dstat
 + download and put jdk1.6.0_35.tar.gz under deploy directory
 + install rssh/benchmarkSQL/sqlite3
<pre><code>
  cd pkgs/rssh
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
  target_url="http://api.$suggest_url" # e.g. api.cloudfoundry.com

  admin_user=foobar@vmware.com         # admin user
  admin_pass=p                         # admin password

  service_type=postgresql              # service type: postgresql or mysql
  service_plan=xxx                     # service plan
  service_version=yyy                  # postgresql: 9.0 or 9.1 mysql: 5.1 or 5.5
  # 0 or 1 == false or true
  service_wardenized=1                 # whether use warden

  user_prefix=performance              # prefix of test user's username
  user_passwd=p                        # test user's password

  app_prefix="${service_type}_worker"  # prefix of test app's name

  use_default_user=0                   # whether use the default user? non-default user might be interrupted by long timer killer_

  # create necessary directories
  log_dir=$base_dir/var/logs
  token_dir=$base_dir/var/tokens
  mkdir -p $log_dir
  mkdir -p $token_dir

  remote_db=/var/vcap/store/${service_type}_node.db
  local_db=$base_dir/var/${service_type}_node.db
</pre></code>
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
+ cd bin

+ ./instance.sh                    # you could run cleanup.sh before to cleanup all provisioned instances)

+ ./deploy.sh                      # deploy benchmarkSQL and JDK to client nodes
                                   # generate benchmark prop files and benchmark scripts of benchmarkSQL

+ ./dispatch_load.sh               # copy prop files and benchmark scripts to client nodes

+ ./run.sh prepare                 # recreate tables and indexes in all instances
                                   # non-blocking, you should use ./check_logs.sh prepare to check whether it is finished

+ ./run.sh preload                 # preload data to instances
                                   # non-blocking, you should use ./check_logs.sh preload to check whether preloading is finished

+ ./run.sh benchmark               # run the benchmark (blocking util the test is finished)

+ ./run.sh report                  # generate report in each client node

+ ./fetch_log.sh                   # fetch logs from client nodes, remember the timestamp

+ ./parse_log.sh logs/$timestamp   # parse the log files to get the result report, the timestamp is 

Tips: 
  - you could speficy the timestamp when run ./run.sh benchmark $timestamp & ./fetch_log.sh $timestamp & ./parse_logs.sh logs/$timestamp

## How to understand the result report
TODO

