#!/bin/bash
# 说明:
# 自动处理 zabbix上的 "Zabbix agent on x.x.x.x is unreachable for 5 minutes" 此类报警;
# 取本机在zaibbix上items agent.ping最后一次状态上报时间戳,当与本地时间戳相差超过5分钟时;本机测试ping zabbix-server,如果可以ping通,则尝试重启zabbix-agent一次;
# by fhb
# 20170703 
# v1.1

# access_log
access_log='/tmp/zabbix_agent.log'

# path
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin

# 从zabbix接口取到auth token;
get_token () {
	username='yunfancdn'
	passwd='yunfan_cdn'
	curl --connect-timeout 8 -m 10 -H 'Content-Type:application/jsonrequest' -d '{"jsonrpc":"2.0","method":"user.login","params":{"user":"'$username'","password":"'$passwd'"},"id":1,"auth":null}' "http://cdn1.zabbix.yfcdn.net/api_jsonrpc.php" -so /tmp/zabbix.$$ &>/dev/null
	if [ -f "/tmp/zabbix.$$" ];then
		auth_token=`cat /tmp/zabbix.$$ | awk -F '[:",]+' '/result/ {print $5}'`

		# 删除临时文件
		find /tmp/ -name "zabbix.$$" -exec rm {} \;

	else
		auth_token=''
	fi
	
	if [ `echo $auth_token | grep -v ^$ | wc -l` -eq 0 ];then
		# 没有获取到hostids,返回1;
		echo "1"
	else
		echo $auth_token
	fi 
}

# 从zabbix接口取到本机对应的hostid;
get_hostids () {
	key=$1
	name=$HOSTNAME
	curl --connect-timeout 8 -m 10 -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"host.get","params":{"output":["hostid","name"],"filter":{"host":"'$name'"}},"auth":"'$key'","id":1}' "http://cdn1.zabbix.yfcdn.net/api_jsonrpc.php" -so /tmp/zabbix.$$ &>/dev/null
	if [ -f "/tmp/zabbix.$$" ];then
		hostids=`cat /tmp/zabbix.$$ | awk -F '[:",'[''{']+' '/result/ {print $6}'`

		# 删除临时文件
		find /tmp/ -name "zabbix.$$" -exec rm {} \;
	else
		hostids=''
	fi
	
	if [ `echo $hostids | grep -v ^$ | wc -l` -eq 0 ];then
		# 没有获取到hostids,返回1;
		echo "1"
	else
		echo $hostids
	fi
}
	
# 根据hostid取本机对应的agent.ping的itemsid;
get_itemsid () {
	key=$1
	hostids=$2
	curl --connect-timeout 8 -m 10 -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"item.get","params": {"output": "extend", "hostids": "'$hostids'","search": {"key_": "agent.ping"},"sortfield": "name"},"auth": "'$key'","id": 1}' "http://cdn1.zabbix.yfcdn.net/api_jsonrpc.php" -so /tmp/zabbix.$$ &>/dev/null
	if [ -f "/tmp/zabbix.$$" ];then
		itemsid=`cat /tmp/zabbix.$$ |  awk -F '[,[{]+' 'BEGIN {OPS="\n"} {for(i=1;i<=NF;i++) print $i}' | awk -F '[":]+' '/itemid/ {print $3}'`

		# 删除临时文件
		find /tmp/ -name "zabbix.$$" -exec rm {} \;
	else
		itemsid=''
	fi

        if [ `echo $itemsid | grep -v ^$ | wc -l` -eq 0 ];then
                # 没有获取到itemsid,返回1;
                echo "1"
        else
                echo $itemsid
        fi
}

# 根据agent.ping的itemsid取本机最后一次上报数据的时间戳;
get_history () {
	key=$1
	itemids=$2
	curl --connect-timeout 8 -m 10 -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"history.get","params": {"output": "extend","itemids": "'$itemids'","sortfield": "clock","sortorder": "DESC","limit":1},"auth": "'$key'","id": 1}' "http://cdn1.zabbix.yfcdn.net/api_jsonrpc.php" -so /tmp/zabbix.$$ &>/dev/null
	if [ -f "/tmp/zabbix.$$" ];then
		time=`cat /tmp/zabbix.$$ | awk -F '[,[{]+' 'BEGIN {OPS="\n"} {for(i=1;i<=NF;i++) print $i}' |  awk -F '[":]+' '/clock/ {print $3}'`

		# 删除临时文件
		find /tmp/ -name "zabbix.$$" -exec rm {} \;
	else
		time=''
	fi

	if [ `echo $time | grep -v ^$ | wc -l` -eq 0 ];then
                # 没有获取到time,返回1;
               	echo  "1"
        else
                echo $time
        fi
}

# 重启zabbix agent 并将结果记录到日志中;
restart_agent () {
	/etc/init.d/zabbix-agent restart &> /dev/null
	if [ $? -eq 0 ];then
		echo "`date "+%F %T"` l:$now z:$last_upload_time zabbix agent restart success" >> $access_log
	else
		echo "`date "+%F %T"` l:$now z:$last_upload_time zabbix agent restart fail" >> $access_log
	fi
}

# 防止脚本积压;
script_name=`basename $0`
process=`ps -ef | grep "$script_name" |grep -v grep | wc -l`
if [ $process -gt 2 ];then
	echo "检测到脚本已经在运行,不执行此脚本,退出!"
	exit 1
fi

# 收集本机在zabbix监控的相关信息; 
key=$(get_token)
if [ "$key" != "1" ];then
	# 取本机对应的hostids;
	hostid=$(get_hostids $key)
	if [ "$hostid" != "1" ];then
		# 取本机hostids对应的itemids;
		itemsid=$(get_itemsid $key $hostid)
		if [ "$itemsid" != "1" ];then
			# 取本机agent.ping 最后一次上报的时间戳; 
			time_value=$(get_history $key $itemsid)
			if [ "$time_value" == "1" ];then
				echo "`date "+%F %T"` get $HOSTNAME agent.ping upload time fail" >> $access_log
				exit 1
			fi
		else
			echo "`date "+%F %T"` get $HOSTNAME itemsid fail" >> $access_log
			exit 1
		fi
	else
		echo "`date "+%F %T"` get $HOSTNAME hostids fail" >> $access_log
		exit 1
	fi
else
	echo "`date "+%F %T"` get zabbix auth token fail" >> $access_log
	exit 1
fi

# 本机的时间戳和agent最后一次上报时间相差超过300s,重启一次zabbix-agent;
now=`date "+%s"`
last_upload_time=$time_value
value=`echo "$now - $last_upload_time" | bc`
if [ $value -gt 300 ];then

	# 防止zabbix-agent频繁重启;
	if [ -f $access_log ];then
		last_restart=`cat $access_log | awk -F '[ :]+' '/restart/ {print $6}' | tail -n 1`
		now=`date "+%s"`
		if [ -n $last_restart ];then
			num=`echo "$now - $last_restart" | bc`
			if [ $num -le 300 ];then
				echo "check zabbix agent has restart 5 minutes before, prevent frequent restart and exit"
				exit 1
			else
				restart_agent				
			fi
		else
			restart_agent
		fi
	else
		restart_agent
	fi
else
	echo "`date "+%F %T"` l:$now z:$last_upload_time zabbix agent is ok" >> $access_log
fi
