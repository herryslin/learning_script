#!/bin/bash
datetime=`date '+%F-%T'`
file='/var/log/ktserver_monitor.log'
thread='/usr/local/bin/ktserver'
ipaddr=`/sbin/ifconfig|grep "inet addr"|grep -v "127.0.0.1"|cut -d: -f2|awk '{print $1}'`
num=`ps -ef|grep -E "$thread"|grep -v "grep"|wc -l`
if [ $num -lt 1 ];then
   echo "$datetime thread less than 1 , something must be wrong." >> $file
   echo "你好，$datetime 监测到服务器 $ipaddr $thread 挂了.拉起脚本进行重启.请确认是否存在异常." | mail -s '异常-进程监控' -r zabbix@kuaibo.cn center@kuaibo.cn
   /etc/init.d/ktserver start
else
   echo "$datetime still alive..." >> $file
fi

filesize=`stat -c %s $file`
if [ $filesize -gt 5242880 ];then
    cat /dev/null > $file
fi

