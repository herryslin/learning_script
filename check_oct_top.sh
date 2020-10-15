#!/bin/bash
# 针对ulog线程cpu使用率的监控
yunfancdn_id=`ps axu|grep yunfancdn |grep -v grep |head -n 1 |awk '{print $2}'`

toplist=`top -b -n 3 -Hp $yunfancdn_id`

num=`echo "$toplist" |grep ulog|awk '{sum+=$9}END{print sum}' |awk -F '.' '{print $1}'`

if [ "$num" -gt "200" ];then
	echo "1"
else
	echo "0"
fi
