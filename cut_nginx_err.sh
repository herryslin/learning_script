#!/bin/bash

#目录以及文件名
log_path=/data/log/nginx
log_file=$log_path/`uname -n`

#日期时间变量
start_day=`date -d "10 mins ago" +%Y/%m/%d`
start_day1=`date -d "10 mins ago" +%Y%m%d`

start_time=`date -d "10 mins ago" +%H:%M`
start_time1=`echo $start_time|sed 's/.$//'`

start_time2=`date -d "10 mins ago" +%H%M`
start_time3=`echo $start_time2|sed 's/.$/0/'`

#过滤日志
cat /data/log/nginx/error.log|grep "$start_day $start_time1" > $log_file

#压缩日志
cd $log_path && gzip `basename $log_file`

#上传日志
/usr/bin/osscmd put $log_file.gz oss://ngx-log/json-log/error-log/$start_day1/$start_time3/`uname -n`.gz 

if [ $? -eq 0 ];then
        rm -f  $log_file.gz
        echo "`date +'%F %T'` $log_file.gz upload file success!" >> /tmp/upload_nginx_error.log
else
	rm -f $log_file.gz
        echo "`date +'%F %T'` $log_file.gz upload file failed!" >> /tmp/upload_nginx_error.log
fi
