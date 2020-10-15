#!/bin/bash
pid=`/bin/ps -aux|grep yunfancdn |egrep -v 'auto|grep'|awk '{print $2}'`
data=`/usr/bin/top -Hp $pid -n1 -b |grep "root"|awk '{sum += $9};END {print sum}'`
echo "$data"

