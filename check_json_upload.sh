#!/bin/bash
#检查日志是否还有没上传
#yifan 20160525 update
#buxiafeng 20170302 edit add check json upload

######################check upload json log##################################
log_path=/data/log/nginx

#检查3分钟前是否有未上传的.json日志

cd $log_path

for i in `find . -type f -iname '*.json' -mmin +3|sed 's/.\///g'`
do
    gzip $i
    nyr=`echo $i | awk -F'[_]' '{print $1}'`
    sf=`echo $i | awk -F'[_]' '{print $2}' |cut -d'.' -f1`
    md5num=`md5sum ${i}.gz|awk '{print $1}'`
    /usr/bin/osscmd put $i.gz oss://ngx-log/json-log/$nyr/$sf/`uname -n`.gz --headers="Content-MD5:$md5num" --check_md5=true
    if [ $? -eq 0 ];then
        echo "`date +'%F %T'` $i reupload" >> /tmp/upload_json.log
        mv $i.gz /data/log/temp/
        rm -f $i
    fi
done

#检查3分钟前是否有未上传的.json.gz日志

for i in `find . -type f -iname '*.json.gz' -mmin +3|sed 's/.\///g'`
do
    nyr=`echo $i | awk -F'[_]' '{print $1}'`
    sf=`echo $i | awk -F'[_]' '{print $2}' |cut -d'.' -f1`
    #/usr/bin/alioss --file  $i --key json-log/$nyr/$sf/`uname -n`.gz
    md5num=`md5sum $i|awk '{print $1}'`
    /usr/bin/osscmd put $i oss://ngx-log/json-log/$nyr/$sf/`uname -n`.gz --headers="Content-MD5:$md5num" --check_md5=true
    if [ $? -eq 0 ];then
        echo "`date +'%F %T'` $i reupload" >> /tmp/upload_json.log
        mv $log_path/$i /data/log/temp/
    fi
done
