#!/bin/bash
cur_dir=`dirname $0`
cd $cur_dir
bundle config build.pg --with-pg-dir=/var/vcap/packages/libpq
bundle config build.mysql2 --with-mysql-dir=/var/vcap/packages/mysqlclient --with-mysql-include=/var/vcap/packages/mysqlclient/include/mysql
bundle install  --deployment
cd -
