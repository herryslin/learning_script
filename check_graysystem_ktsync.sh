#!/bin/bash
#配置文件kt是否存在，并且是否与本机kt数值一直,本机到kt通信是否正常
real_kt=`cat /etc/init.d/ktserver |grep masterhost|head -n 1|awk -F '=' '{print $2}'`
graysystem_kt=`cat /opt/agent/conf/agent.conf|grep 2379|awk -F '"' '{print $2}'|awk -F ':' '{print $1}'`
network=`ping $real_kt  -c 5`
loss=`echo $network|awk -F ',' '{print $3}'|awk -F '%' '{print $1}'`
edge_kt_port=`cat /etc/init.d/ktserver |grep masterport=1914`
middle_kt_port=`cat /etc/init.d/ktserver |grep masterport=1913`
if [ "$edge_kt_port" == "masterport=1914" ];then
    if [ "$graysystem_kt" != "$real_kt" ] || [ $loss -gt 20 ]; then
           sed -i "s/$graysystem_kt/$real_kt/g" /opt/agent/conf/agent.conf && /opt/agent/bin/agent.sh start  >> /tmp/graysystem.log
           echo 1
    else
           echo 0
    fi
elif [ "$middle_kt_port" == "masterport=1913" ];then
    if [ "$graysystem_kt" != "127.0.0.1" ]; then
          sed -i "s/$graysystem_kt/127.0.0.1/g" /opt/agent/conf/agent.conf && /opt/agent/bin/agent.sh start  >> /tmp/graysystem.log
          echo 1
    else
          echo 0
    fi
else
          echo 0

fi
