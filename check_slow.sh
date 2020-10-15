#!/bin/bash

hour=`date +%H%M -d '5 min ago'|cut -c 1-2`
min1=`date +%H%M -d '5 min ago'|cut -c 3`
min2=`date +%H%M -d '5 min ago'|cut -c 4`

if [ ${min2} -lt 5 ];then
        uv=`cat /data/log/nginx/access.log |grep "2017:$hour:$min1[0-4]:"|grep "\.ts"|wc -l`
        slow=`cat /data/log/nginx/access.log |grep "2017:$hour:$min1[0-4]:"|grep "\.ts"|awk '{if ((\$8==200||\$8==206) && (\$(NF-6)>0) && (\$9/\$(NF-6)/1024/1024*8)<2) {print}}'|wc -l`
        per=`gawk -v x=$slow -v y=$uv 'BEGIN{printf "%.2f",x/y*100}'`
        if [ $(echo "$per < 10"|bc) = 0 ];then
                echo $per
                #message=$(echo -e "`hostname`_TS文件慢速比超标:`date +%H%M -d '5 min ago'`_$per% (TS文件发送速度小于2M/S)"|od -t x1 -A n -v -w1000000000 | tr " " %)
                #/usr/bin/curl "http://115.182.75.13:15001/openwx/send_group_message?displayname=报警运维群&content=$message"
        else
                echo $per
        fi
else
        uv=`cat /data/log/nginx/access.log |grep "2017:$hour:$min1[5-9]:"|grep "\.ts"|wc -l`
        slow=`cat /data/log/nginx/access.log |grep "2017:$hour:$min1[5-9]:"|grep "\.ts"|awk '{if ((\$8==200||\$8==206) && (\$(NF-6)>0) && (\$9/\$(NF-6)/1024/1024*8)<2) {print}}'|wc -l`
        per=`gawk -v x=$slow -v y=$uv 'BEGIN{printf "%.2f",x/y*100}'`
        if [ $(echo "$per < 10"|bc) = 0 ];then
                echo $per
                #message=$(echo -e "`hostname`_TS文件慢速比超标:`date +%H%M -d '5 min ago'`_$per% (TS文件发送速度小于2M/S)"|od -t x1 -A n -v -w1000000000 | tr " " %)
                #/usr/bin/curl "http://115.182.75.13:15001/openwx/send_group_message?displayname=报警运维群&content=$message"
        else
                echo $per
        fi
fi
