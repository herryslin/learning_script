#!/bin/bash
#每分钟切割nginx access log,upload them to aliyun
#zrw 20160219

#billing log path
log_path=/data/log/nginx/billing/

PID=/var/run/nginx.pid

log_file=$log_path/billing_`date +"%Y%m%d_%H%M"`.log

mv $log_path/billing.log $log_file

kill -USR1 `cat $PID`
