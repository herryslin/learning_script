#!/bin/bash

ps -ef | grep yunfancdn | grep -v grep &>/dev/null

if [ $? -ne 0  ];then
  echo `date +'%F %T'`>>/root/restartcdn.txt && /usr/sbin/yunfancdn.sh start
        if [ $? -eq 0  ] && [ -f /core.* ];then
          debug_num=`rpm -qa |grep yunfancdn-debuginfo|wc -l`
          if [ $debug_num -eq 0 ];then
                  banben=`rpm -q yunfancdn|sed 's/yunfancdn/yunfancdn-debuginfo/g'`
                  yum install ${banben} -y
          else
                  yum downgrade ${banben} -y
                  yum upgrade ${banben} -y
          fi
          gdb -c  /core.* -q --batch --ex "set height 0" -ex "bt"  > /data/zmj/bt_oct_core.txt
          bt_message=`cat /data/zmj/bt_oct_core.txt`
          bt_message1=$(echo -e "$bt_message"|od -t x1 -A n -v -w1000000000 | tr " " %)
          curl "http://alarm.api.yfcdn.net:15003/send_message?content=bt_$HOSTNAME---$version--OCT_core-$bt_message1"
          mv /core.* /opt/
          ls -lt /opt/core.*| awk '{if(NR>3){print "rm "$9}}' | sh

        fi
fi

#check nginx
ps -ef | grep nginx | grep -v grep &>/dev/null

if [ $? -ne 0  ];then
  echo `date +'%F %T'`>>/root/nginx.txt && /etc/init.d/nginx start
fi

#check zabbix
ps -ef | grep zabbix | grep -v grep &>/dev/null

if [ $? -ne 0  ];then
  echo `date +'%F %T'`>>/root/zabbix-agent.txt && /etc/init.d/zabbix-agent start
fi

#check ops
ps -ef | grep ops | grep -v grep

if [ $? -ne 0  ];then
  echo `date +'%F %T'`>>/root/ops.txt && cd /usr/local/agents && ./control start
fi

#check redis
ps -ef | grep redis | grep -v grep &>/dev/null

if [ $? -ne 0  ];then
  echo `date +'%F %T'`>>/root/redis.txt && /etc/init.d/redis start
fi

#check redis 防火墙
#1、未添加白名单和黑名单
if [ "$(/sbin/iptables -nL|grep 6379|grep ACCEPT|wc -l)" -lt "3" ] && [ "$(/sbin/iptables -nL|grep 6379|grep DROP|grep "0.0.0.0"|wc -l)" -lt "1" ];then
        date +'%F %T' >>/root/redis.txt
        /sbin/ip a|grep inet|grep -v inet6|awk '{print $2}'|awk -F '.' 'BEGIN{OFS="."}{print $1,$2,$3}'|sort -nr |uniq -c |awk '{print $2}' >/tmp/ip
        for i in $(cat /tmp/ip)
                do
                        /sbin/iptables -A INPUT -s $i.0/24 -p tcp --dport 6379 -j ACCEPT
                done
        /sbin/iptables -A INPUT -s 127.0.0.1 -p tcp --dport 6379 -j ACCEPT
        /sbin/iptables -A INPUT -s 115.182.75.13 -p tcp --dport 6379 -j ACCEPT
        /sbin/iptables -A INPUT -s 58.67.196.139 -p tcp --dport 6379 -j ACCEPT
        /sbin/iptables -A INPUT -s 115.182.75.15 -p tcp --dport 6379 -j ACCEPT

        /sbin/iptables -A INPUT -p tcp --dport 6379 -j DROP
        echo "未添加redis防火墙，脚本自动重新添加redis防火墙" >>/root/redis.txt
fi

#2、添加了白名单，但是未添加黑名单
if [ "$(/sbin/iptables -nL|grep 6379|grep ACCEPT|wc -l)" -gt "3" ] && [ "$(/sbin/iptables -nL|grep 6379|grep DROP|grep "0.0.0.0"|wc -l)" -lt "1" ];then
        date +'%F %T' >>/root/redis.txt
        /sbin/iptables -A INPUT -p tcp --dport 6379 -j DROP
        echo "添加了redis白名单、但是未添加redis黑名单,脚本自动重新添加redis防火墙" >>/root/redis.txt
fi

#、添加了黑名单、但是未添加白名单
if [ "$(/sbin/iptables -nL|grep 6379|grep ACCEPT|wc -l)" -lt "3" ] && [ "$(/sbin/iptables -nL|grep 6379|grep DROP|grep "0.0.0.0"|wc -l)" -ge "1" ];then
        date +'%F %T' >>/root/redis.txt
        /sbin/ip a|grep inet|grep -v inet6|awk '{print $2}'|awk -F '.' 'BEGIN{OFS="."}{print $1,$2,$3}'|sort -nr |uniq -c |awk '{print $2}' >/tmp/ip
        for i in $(cat /tmp/ip)
                do
                        /sbin/iptables -I INPUT -s $i.0/24 -p tcp --dport 6379 -j ACCEPT
                done
        /sbin/iptables -I INPUT -s 127.0.0.1 -p tcp --dport 6379 -j ACCEPT
        /sbin/iptables -I INPUT -s 115.182.75.13 -p tcp --dport 6379 -j ACCEPT
        /sbin/iptables -I INPUT -s 58.67.196.139 -p tcp --dport 6379 -j ACCEPT
        /sbin/iptables -I INPUT -s 115.182.75.15 -p tcp --dport 6379 -j ACCEPT

        echo "添加了redis黑名单、但是未添加redis白名单,脚本自动重新添加redis防火墙白名单" >>/root/redis.txt
fi
