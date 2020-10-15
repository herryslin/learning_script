#!/bin/bash
#每分钟切割nginx json log,upload them to aliyun
#20160524 by zrw
#version v1.2


#日志切割#
#nginx log path
log_path=/data/log/nginx

PID=`cat /var/run/nginx.pid`

#check nginx pid file whether is null
if [ -z "$PID" ]; then
        PID=`ps -ef | grep nginx | grep -v grep | grep master | awk '{print $2}'`
        echo "`date +'%F %T'` nginx pid file not contains pid">>/tmp/upload_json.log
fi

log_file=$log_path/`date +"%Y%m%d_%H%M" -d "-1 minute"`.json

mv $log_path/json.log $log_file


kill -USR1 $PID

#上传阿里云存储#
cd $log_path && gzip `basename $log_file`

sleep 3

if [ ! -f $log_file.gz ];then
        echo "`date +'%F %T'` No nginx log file">>/tmp/upload_json.log
        exit 3
fi

#/usr/bin/alioss --file  $log_file.gz --key json-log/`date +'%Y%m%d' -d "-1 minute"`/`date +"%H%M" -d "-1 minute"`/`uname -n`.gz
md5num=`md5sum $log_file.gz|awk '{print $1}'`
filesize=`stat -c %s $log_file.gz`
/usr/bin/osscmd put $log_file.gz oss://ngx-log/json-log/`date +'%Y%m%d' -d "-1 minute"`/`date +"%H%M" -d "-1 minute"`/`uname -n`.gz --headers="Content-MD5:$md5num" --check_md5=true

if [ $? -eq 0 ];then
        if [ ! -d /data/log/temp/ ];then
                mkdir -pv /data/log/temp/
        fi
        mv $log_file.gz /data/log/temp/

                #回调日志给大数据接口
                logtime1=`date +"%Y%m%d %H:%M" -d "-1 minute"`
                logtime=`date -d "$logtime1" +%s`

                Timestamp=`date +%s`
                Nonce=`echo $Timestamp|cut -c 1-9`
                dm='cdnlogcallback'
                act='cdnlogcallback'
                ak=akakak
                sk=sksksk
                uri='/as.gif'
                str=`echo -n  "$uri?dm=$dm&act=${act}:$Timestamp:$Nonce" |openssl sha1 -hmac $sk|awk '{print $NF}'`
                Authorization=`echo -n "$ak:$str" |base64 -i`

                curl -s -X POST --connect-timeout 5 -m 5 --retry 2 -H "X-YF-Nonce: $Nonce" -H "Connection: keep-alive" -H "Content-Type: application/json" -H "Authorization: $Authorization" -H "X-YF-Timestamp: $Timestamp" -d '{"dm":"'$dm'","act":"'$act'","fmt":"json","data":["{\"OSSType\":\"aliyun\",\"Uri\":\"json-log/'`date +'%Y%m%d' -d "-1 minute"`/`date +"%H%M" -d "-1 minute"`/`uname -n`.gz'\",\"SendTime\":'`date +%s`',\"LogTime\":'$logtime',\"BucketName\":\"ngx-log\",\"HostName\":\"'`uname -n`'\",\"FileSize\":'$filesize'}"]}' http://box.log.yunfancdn.com/as.gif

else
        echo "`date +'%F %T'` $log_file.gz upload file failed!" >> /tmp/upload_json.log
fi

