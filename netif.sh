#!/bin/bash
netifs=`/sbin/ip addr | grep ^[0-9] | egrep -v 'DOWN|lo' | awk '{print $2}' | tr -d :`
ip=`/sbin/ifconfig |head -2|tail -1|awk '{print $2}' |cut -d":" -f2`
for i in $netifs
do
        spd=`ethtool $i | grep -i speed | grep -Po '[0-9]+'`
        if [ "$spd" -lt 1000 ];then
		sub="$ip 网卡报警"
		cont="$i current speed is ${spd}Mb/s"
		python /data/script/send_qqmail.pyc "$sub" "$cont"  "['279826702@qq.com','1278652242@qq.com','514108793@qq.com','244624832@qq.com','875687255@qq.com','980882808@qq.com','1038333786@qq.com','zabbixnew@kuaibo.cn']"
        fi      
done
