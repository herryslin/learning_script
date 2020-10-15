#!/bin/sh
time2=`date +%Y%m%d_%H%M -d '2 minutes ago'`.json.gz
time3=`date +%Y%m%d_%H%M -d '3 minutes ago'`.json.gz
time4=`date +%Y%m%d_%H%M -d '4 minutes ago'`.json.gz
time5=`date +%Y%m%d_%H%M -d '5 minutes ago'`.json.gz
time6=`date +%Y%m%d_%H%M -d '6 minutes ago'`.json.gz
cd /data/log/temp/
lts_num=`zcat $time2 $time3 $time4 $time5 $time6 |grep ltsydzd.qq.com|awk -F'\":\"' '{print $33}'|awk -F'\",' '{if($1 ~ 50.) print $1}'|grep -v PURGE|wc -l`
ugc_num=`zcat $time2 $time3 $time4 $time5 $time6 |grep ugcydzd.qq.com|awk -F'\":\"' '{print $33}'|awk -F'\",' '{if($1 ~ 50.) print $1}'|grep -v PURGE|wc -l`
lm_num=`zcat $time2 $time3 $time4 $time5 $time6 |grep lmydzd.qq.com|awk -F'\":\"' '{print $33}'|awk -F'\",' '{if($1 ~ 50.) print $1}'|grep -v PURGE|wc -l`
meitu_num=`zcat $time2 $time3 $time4 $time5 $time6 |grep mvvideo|awk -F'\":\"' '{print $33}'|awk -F'\",' '{if($1 ~ 50.) print $1}'|grep -v PURGE|wc -l`
cdn3rd8live_num=`zcat $time2 $time3 $time4 $time5 $time6 |grep cdn3rd8live.voole.com|awk -F'\":\"' '{print $33}'|awk -F'\",' '{if($1==404) print $1}'|grep -v PURGE|wc -l`
date=`date "+%F %T"`
date1=`date "+%F %T" -d "5 minutes ago"`

lts_message="ltsydzd的5xx数目超过10条,条数为:${lts_num},时间:${date}-${date1},主机名:$HOSTNAME"
lts1_message=$(echo -e "$lts_message"|od -t x1 -A n -v -w1000000000 | tr " " %)
if [ $lts_num -gt 10 ];then
	curl "http://alarm.api.yfcdn.net:15001/send_message?content=$lts1_message"
else
	echo 0
fi


ugc_message="ugcydzd的5xx数目超过10条,条数为:${ugc_num},时间:${date}-${date1},主机名:$HOSTNAME"
ugc1_message=$(echo -e "$ugc_message"|od -t x1 -A n -v -w1000000000 | tr " " %)
if [ $ugc_num -gt 30 ];then
	curl "http://alarm.api.yfcdn.net:15001/send_message?content=$ugc1_message"
else
	echo 0
fi

lm_message="lmydzd的5xx数目超过10条,条数为:${lm_num},时间:${date}-${date1},主机名:$HOSTNAME"
lm1_message=$(echo -e "$lm_message"|od -t x1 -A n -v -w1000000000 | tr " " %)
if [ $lm_num -gt 10 ];then
        curl "http://alarm.api.yfcdn.net:15001/send_message?content=$lm1_message"
else
        echo 0
fi

meitu_message="mvvideo的5xx数目超过10条,条数为:${meitu_num},时间:${date}-${date1},主机名:$HOSTNAME"
meitu1_message=$(echo -e "$meitu_message"|od -t x1 -A n -v -w1000000000 | tr " " %)
if [ $meitu_num -gt 10 ];then
        curl "http://alarm.api.yfcdn.net:15001/send_message?content=$meitu1_message"
else
        echo 0
fi
