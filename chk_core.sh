#!/bin/bash
#chk_core by zmj
mkdir -p /data/zmj
n1=`ls /data/ngx_core  2>/dev/null | wc -l`
n2=`ls /core.*  2>/dev/null | wc -l`
version=`cat /etc/redhat-release |awk '{print $(NF-1)}'`
#ip=`ip a|grep global|grep -v 127.0.0.1|grep -v "/32"|awk '{print $2}'|awk -F '/' '{print $1}'|grep -v ^10\.`
if [ $n1 -gt 0 ] ; then
	[ ! -d /root/debug-tools ] && mkdir -p /root/debug-tools
	if [ ! -f /root/debug-tools/lua_gdb_install.sh ];then
		wget -S 'ospf.yunfancdn.com/lua_gdb_install.sh' -e http-proxy=115.238.147.189 -O /root/debug-tools/lua_gdb_install.sh
	fi 
	/bin/sh /root/debug-tools/lua_gdb_install.sh
	debug_num=`rpm -qa |grep openresty-debuginfo|wc -l`
	if [ $debug_num -eq 0 ];then
		yum install openresty-debuginfo -y
	fi
	for i in `ls /data/ngx_core/core.*`
	do
		gdb -c $i -q --batch --ex "set height 0" -ex "lbt" > /data/zmj/lbt_core.txt
		gdb -c $i -q --batch --ex "set height 0" -ex "bt"  > /data/zmj/bt_core.txt
		cat /data/zmj/bt_core.txt |grep ^#|head -6 > /data/zmj/bt_6core.txt
		bt_message=`cat /data/zmj/bt_6core.txt`
		lbt_message=`cat /data/zmj/lbt_core.txt`
		bt_message1=$(echo -e "$bt_message"|od -t x1 -A n -v -w1000000000 | tr " " %)	
		lbt_message1=$(echo -e "$lbt_message"|od -t x1 -A n -v -w1000000000 | tr " " %)	
		curl "http://cdn.zabbix.yfcdn.net:16001/openqq/send_group_message?uid=421117992&content=bt_$HOSTNAME---$version--ng_core-$bt_message1"
		curl "http://cdn.zabbix.yfcdn.net:16001/openqq/send_group_message?uid=421117992&content=lbt_$HOSTNAME---$version--ng_core-$lbt_message1"
		mv $i /tmp/
	done
	ls -lt /tmp/core.*| awk '{if(NR>3){print "rm "$9}}' | sh
else
	echo 0
fi
