#!/bin/bash
#block device info for disk store
#author by buxiafeng 20170525
#change by zhoumingjian 20170528
case "$1" in
	total)
		/bin/echo -n status|nc 127.0.0.1 5210|grep lvdata|grep iostatus|awk '{print $3/1000/1000}'|awk '{a+=$1}END{print a}'
		;;
	used)
		/bin/echo -n status|nc 127.0.0.1 5210|grep lvdata|grep iostatus|awk '{print $4/1000/1000}'|awk '{a+=$1}END{print a}'
		;;
	free)
		/bin/echo -n status|nc 127.0.0.1 5210|grep lvdata|grep iostatus|awk '{print $5/1000/1000}'|awk '{a+=$1}END{print a}'
		;;
esac
