auto_benchmarksql_cf
====================

auto scripts for benchmarkSQL

0) you should put jdk_dir.tar.gz under deploy

1) cd pkgs/rssh

   bundle install

   git submodule update --init

   cd deploy/benchmarkSQL
   
   mvn package

2) sudo apt-get install -y sqlite3

3) run instance.sh (you could run cleanup.sh before)

4) run deploy.sh

5) run dispatch_load.sh

6) run run.sh prepare|preload|benchmark

7) run run.sh report

8) run fetch_log.sh

9) run parse_log.sh logs/$timestamp
