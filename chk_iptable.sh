#!/bin/bash
sys=`/sbin/iptables -nL|grep $1|grep $2|wc -l`

if [ `/sbin/iptables -nL|grep -i $1|grep $2|wc -l` -lt $3 ];then
        echo 0
else
        echo 1
fi
