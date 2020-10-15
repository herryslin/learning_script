#!/bin/bash
# Version v1.2
# 报警情况分为
# 1、上次状态异常，则直接报警，并记录本次也为异常状态
# 2、上次异常，本次正常，则不报警
# 3、上次正常，本次异常，则记录状态，不进行报警

wget -S 'ospf.yunfancdn.com/kt_server_num.list' -e http-proxy=v11.yfcdn.net -t 2 -T 10 -O /tmp/kt_server_num.list > /dev/null 2>&1 &
n1=`cat /tmp/kt_server_num.list`
n2=`curl -s localhost:1916/rpc/report|grep count=  |awk -F "[= ]" '{print $2}'`
# 允许本地可以多，但是不可以少（误差最大为 5条）
n3=$(($n2+5))

if [ ${n3}  -lt ${n1} ] ;then
        # 假如异常，则根据上次探测状态判断是否需要报警
        # 1、上次状态异常，则报警
        if [ "$(cat /tmp/last_kt_status.log |grep 1 |wc -l)" -eq "1" ];then
                echo 1
                # 并记录本次的状态
                echo '1' >/tmp/last_kt_status.log
        else
        # 2、不进行报警，记录本次异常状态
                echo 0
                echo '1' >/tmp/last_kt_status.log
        fi
else
        # 3、探测无异常，则不进行报警，并记录本次状态
        echo 0
        echo '0' >/tmp/last_kt_status.log
fi
