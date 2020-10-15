#!/bin/sh
app=`/sbin/lsmod |grep app|wc -l`
bbr=`lsmod |grep bbr|wc -l`
if [ $bbr -ne 0 ];then
		echo 3
elif [ -f /appex/bin/lotServer.sh  ];then
	if [ $app -ne 0 ];then
		echo 1
	else
		echo 2
	fi
else
		echo 0
fi
