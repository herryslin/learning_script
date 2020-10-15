#!/bin/bash
config=$1

if [ $config = "config_lua" ];then
        m=`/bin/hostname|cut -c 1-7`
        n=`cat /opt/app/edge/etc/config.lua|grep myNode|awk '{print $3}'|cut -c 2-8`
        if [ "$m"x = "$n"x ];then
                echo 0;
        else 
                echo 1;
        fi

elif [ $config = "servconf_ini" ];then
        m=`hostname`
        n=`cat /etc/nginx/servconf.ini|grep hostname|awk '{print $3}'|sed 's/"//g'`
        if [ "$m"x = "$n"x ];then
                echo 0;
        else
                echo 1;
        fi

elif [ $config = "mac_id" ];then
        m=`hostname`
        n=`cat /etc/nginx/servconf.ini|grep machine_id|awk '{print $3}'|sed 's/"//g'`
        if [ "$m"x = "$n"x ];then
                echo 0;
        else
                echo 1;
        fi

elif [ $config = "use_kt" ];then
        m=`cat /opt/app/edge/etc/config.lua|grep use_kt|grep true|wc -l`
        if [ $m -eq 1  ];then
                echo 0;
        else
                echo 1;
        fi

elif [ $config = "lua_edge" ];then
        echo `rpm -q lua-edge|awk -F. '{print $2}'|sed 's/-//g'`

elif [ $config = "oct_ver" ];then
        echo `rpm -q yunfancdn|awk -F- '{print $2}'|sed 's/\.//g'`

elif [ $config = "nginx_ver" ];then
        echo `rpm -q openresty|awk -F"el" '{print $1}'|awk -F- '{print $2$3}'|sed 's/\.//g'`

fi
