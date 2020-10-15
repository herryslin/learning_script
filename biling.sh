#!/bin/bash

# 触发报警处理方法：
# 1、首先killall nginx 然后重新启动
# 2、发现2个master 直接禁用
# 3、持续告警，直接禁用
now_time=`date +%s`
up1_time=`echo "$now_time"|awk '{printf("%.1f\n", $1/300)}'|awk -F '.' '{print $1*300}'`
up2_time=`echo "$now_time"|awk '{printf("%.1f\n", $1/300)}'|awk -F '.' '{print ($1 -1)*300}'`
up3_time=`echo "$now_time"|awk '{printf("%.1f\n", $1/300)}'|awk -F '.' '{print ($1 -2)*300}'`
up4_time=`echo "$now_time"|awk '{printf("%.1f\n", $1/300)}'|awk -F '.' '{print ($1 -3)*300}'`
up5_time=`echo "$now_time"|awk '{printf("%.1f\n", $1/300)}'|awk -F '.' '{print ($1 -4)*300}'`

#前 5min 时间点
one_time=`date -d @$up1_time|awk '{print $4}'|cut -c 1-5`
two_time=`date -d @$up2_time|awk '{print $4}'|cut -c 1-5`
thr_time=`date -d @$up3_time|awk '{print $4}'|cut -c 1-5`
fou_time=`date -d @$up4_time|awk '{print $4}'|cut -c 1-5`
fiv_time=`date -d @$up5_time|awk '{print $4}'|cut -c 1-5`

i1=`echo $one_time|sed 's/://g'`
i1date=`date +%Y%m%d_$i1` 
i2=`echo $two_time|sed 's/://g'`
i2date=`date +%Y%m%d_$i2` 
i3=`echo $thr_time|sed 's/://g'`
i3date=`date +%Y%m%d_$i3` 
i4=`echo $fou_time|sed 's/://g'`
i4date=`date +%Y%m%d_$i4` 
i5=`echo $fiv_time|sed 's/://g'`
i5date=`date +%Y%m%d_$i5` 
xitongshijian=`date +%s`

mine_login_time=`curl -s "http://0:8099" -H"host:nginx_monitor"|json2lua |grep miner_last_login_time\"]|awk '{print $3}'|awk -F',' '{print $1}'`
mine_login_shijiancha=$(($xitongshijian-$mine_login_time))


miner_shangbao_time=`curl -s "http://0:8099" -H"host:nginx_monitor"|json2lua |grep miner_last_billing_time\"]|awk '{print $3}'|awk -F',' '{print $1}'`
miner_shangbao_shijiancha=$(($xitongshijian-$miner_shangbao_time))

biling_write_time=`curl -s "http://0:8099" -H"host:nginx_monitor"|json2lua |grep cache_last_write_time\"]|awk '{print $3}'|awk -F',' '{print $1}'`
biling_write_shijiancha=$(($xitongshijian-$biling_write_time))

biling_shangbao_time=`curl -s "http://0:8099" -H"host:nginx_monitor"|json2lua |grep cache_last_billing_report_time\"]|awk '{print $3}'|awk -F',' '{print $1}'`
biling_shangbao_shijiancha=$(($xitongshijian-$biling_shangbao_time))
date=`date +%Y%m%d`

n=`ls -l /data/log/nginx/billing|egrep "$i1date|$i2date|$i3date|$i4date|$i5date"| awk '{print $5}' |grep "^0$"|wc -l`

if [ `echo $HOSTNAME|cut -c 14` == 'K' ];then
	if [ $mine_login_shijiancha -gt 3600 ] || [ $miner_shangbao_shijiancha -gt 600 ] || [ $biling_write_shijiancha -gt 600 ] || [ $biling_shangbao_shijiancha -gt 600 ] || [ $n -eq 5 ] ;then
			echo 1
	else
			echo 0
	fi
else
	if [ $biling_write_shijiancha -gt 600 ] || [ $biling_shangbao_shijiancha -gt 600 ] || [ $n -eq 5 ] ;then
			echo 1
	else
			echo 0
	fi
fi
