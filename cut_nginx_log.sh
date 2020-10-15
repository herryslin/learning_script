#!/bin/bash
#按天切割nginx access log
#时间任务00:00执行


#nginx log path
log_path=/data/log/nginx

PID=/var/run/nginx.pid
[ ! -d  /data/log/backup ] && mkdir -p /data/log/backup/
[ ! -d  /data/log/nginx/backup ] && mkdir -p /data/log/nginx/backup/
mv $log_path/access.log $log_path/backup/access_`date +'%Y%m%d' -d "-1 day"`.log
cp $log_path/dns_access.log $log_path/backup/dns_access_`date +'%Y%m%d' -d "-1 day"`.log  && >$log_path/dns_access.log



kill -USR1 `cat $PID`

find /data/log/backup/ -mtime +5 -type f -exec rm -f {} \;
