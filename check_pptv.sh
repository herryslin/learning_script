#!/bin/sh
time2=`date +%Y%m%d_%H%M -d '2 minutes ago'`.json.gz
time3=`date +%Y%m%d_%H%M -d '3 minutes ago'`.json.gz
cd /data/log/temp/
man=`zcat $time2 $time3  |grep yfcdn.live.pptv.com|awk -F "\"" '$12>1000 {print $12}'|wc -l`
sum=`zcat $time2 $time3  |grep yfcdn.live.pptv.com|wc -l`
s=`echo $(awk 'BEGIN{printf "%.5f\n", '$man'/'$sum' }')`
if [ $man -eq 0 ];then
  s=0
fi
hostname=`hostname`
if [ $(echo "$s >= 0.01"|bc) = 1 ] && [ $(echo "$s < 0.02"|bc) = 1 ];then
   message=`echo $time2_$time3_${hostname}_域名yfcdn.live.pptv.com_nginx_处理时间大于1s的本机占比大于1%,请关注。_$s_$man_$sum`   
   curl "http://alarm.api.yfcdn.net:15001/send_message?content=${message}"
elif [ $(echo "$s >= 0.02"|bc) = 1 ];then
   message1=`echo $time2_$time3_${hostname}_域名yfcdn.live.pptv.com_nginx_处理时间大于1s的本机占比大于2%,请关注。_$s_$man_$sum`   
   curl "http://alarm.api.yfcdn.net:15001/send_message?content=${message1}"
fi
echo $s $man $sum
