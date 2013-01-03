#!/bin/bash
cur_dir=`dirname $0`
cd $cur_dir
/var/vcap/bosh/bin/bundle config build.pg --with-pg-dir=/var/vcap/packages/libpq
/var/vcap/bosh/bin/bundle config build.mysql2 --with-mysql-dir=/var/vcap/packages/mysqlclient --with-mysql-include=/var/vcap/packages/mysqlclient/include/mysql
/var/vcap/bosh/bin/bundle install  --deployment
cd -
