#!/bin/sh
time2=`date +%Y%m%d_%H%M -d '2 minutes ago'`.json.gz
time3=`date +%Y%m%d_%H%M -d '3 minutes ago'`.json.gz
time4=`date +%Y%m%d_%H%M -d '4 minutes ago'`.json.gz
time5=`date +%Y%m%d_%H%M -d '5 minutes ago'`.json.gz
time6=`date +%Y%m%d_%H%M -d '6 minutes ago'`.json.gz
cd /data/log/temp/
n=`zcat $time2 $time3 $time4 $time5 $time6 |grep mvvideo10.meitudata.com|awk -F'\":\"' '{print $33}'|awk -F'\",' '{if($1 ~ 50.) print $1}'|wc -l`
echo $n
