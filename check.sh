#!/bin/bash
# Author:       xz

echo 'Version: v7.3' >/tmp/check.log
name=`cat /etc/nginx/servconf.ini |grep hostname |awk -F '"' '{print $2}'`

#帮助获取及功能说明模块
function help
{
        echo -e "\n\t\t\t*****使用方法*****\n"
        echo -e "1、登录 219.83.188.149 上,将需要检查的版本信息加入该文件中 /usr/local/yunfancdn/banben.list"
        echo -e "2、更新check脚本sudo wget -S 'ospf.yunfancdn.com/check.sh' -e http-proxy=v11.yfcdn.net -O /data/script/check.sh"
        echo -e "3、执行脚本 sh /data/script/check.sh"

        echo -e "\n\t\t\t*****功能说明*****\n"

        echo -e "一、edgeadmin后台相关配置部分"
        echo "1、edage-admin设备码校验有无异常"
        echo "2、edage-admin后台主机名与/etc/nginx/servconf.ini中是否一致"
        echo "3、edage-admin后台网卡带宽与设备网卡真实带宽是否一致"
        echo "4、判断同组内网ip是否全部都ping通(ping 20个包看是否有丢包和明显延时),并且检查相互间8000端口的连通性"
        echo "5、判断当前主机名是否和 config_lua 一致"
        echo "6、判断edage-admin后台是否有配置正确的内网ip(不配置则不会有一致性哈希)"
        echo "7、判断同组设备是为同一个网段(假如不在同一个网段则防火墙规则校验会有异常)"

        echo -e "\n二、查重要服务的版本信息模块"
        echo "1、检查各个版本信息(openresty、lua-edge、yunfancdn等，支持自定义添加检查任意多的服务)"
        echo "2、检查计划任务与标准库是否一致"
        echo "3、检查计划任务中的脚本在设备上是否存在"
	echo "4、检查/etc/zabbix/zabbix_agentd.conf的脚本在设备上是否存在"
	echo "5、检查ospf"
	echo "6、检查/etc/nginx/nginx.conf文件里json日志字段数目检查"
	echo "7、检查/etc/yum.repos.d/yfcustom.repo 中 gpgcheck 是否为1"
	echo "8、检查/etc/salt/minion_id 是否和主机名一致"
	echo "9、检查是否关闭了swap缓存"

        echo -e "\n三、检查系统的相关重要配置"
        echo "1、检查是否开启了防火墙"
        echo "2、检查防火墙启动脚本未添加至开机启动项目中"
        echo "3、检查防火墙规则是否被save了"
        echo "4、判断系统版本是否小于 2.6.32-504"
        echo "5、判断点播设备是否安转锐速或者启用了bbr(假如未安装则提供一键安装脚本)"
        echo "6、针对安装锐速的设备、判断加速网卡名称、加速带宽是否正确"
        echo "7、判断是否有进行软中断优化操作(假如未进行该步操作的，则显示操作方法)"
	echo "8、检查/opt/app/edge/etc/config.lua里的edge_config等key"
	echo "9、检查/etc/resolv.conf是否配置正确"

        echo -e "\n四、针对重要服务参数检查"
        echo "1、use_kt配置检查"
        echo "2、检查sshd服务是否开启了禁用dns"
        echo "3、检查判断edge-admin后台是否有配置上层"
        echo "4、检查是否开启了ops日志上传功能"
        echo "5、检查upload_json.sh,zabbix.conf等相关脚本是否正确"
	echo "6、检查本地时间是否异常"
	echo "7、检查KT同步是否异常"
	echo "8、检查https证书异常"
	echo "9、检查大内存设备oct使用内存是否设置合理"

        echo -e "\n五、重要服务进程及服务状态检查"
        echo "1、nginx、yunfancdn、ops、ktserver、redis、flash843、zabbix进程数目检查"
        echo "2、绑定本机curl连续访问10次，判断是否正常(每次用时小于2s)"
        echo "3、针对矿机，看是否有添加矿工账号密码"
        echo "4、联动zabbix数据库、检查设备是否有开启监控"
        echo "5、判断nginx是否起了多个master进程"
	echo "6、针对矿机，检查到验证域名auth.yunfancdn.com网络是否异常"
	echo "7、针对点播设备，是否误添加了矿工账号密码"
        echo "8、针对点播非矿机设备，当前活跃挂载磁盘是否小于9块"

        echo ""

}


#获取同组设备状态的函数
function get_tongzu_zt
{
        time=`date +%s`
        jiedian_zu=`cat /etc/nginx/servconf.ini|grep hostname|awk -F '= "' '{print $2}'|cut -c 1-7`
        md5_sum=`echo -n "yfcdn@yfcloud.com$time"|/usr/bin/md5sum|awk '{print $1}'`
        #获取同组设备的状态
        wget -S "https://edgeadmin.yfcloud.com/openapi/machine/nodes/$jiedian_zu?t=$time&sign=$md5_sum" -t 1 -T 5 -O /tmp/tongzu_zt &>/dev/null
        if [ "$(cat /tmp/tongzu_zt|grep $jiedian_zu |wc -l)" -gt "0" ];then
		zhuang_tai=`echo "获取同组设备节点信息成功"`
        else
                /usr/bin/curl --connect-timeout 10 -m 10 --retry 2 -v "https://edgeadmin.yfcloud.com/openapi/machine/nodes/$jiedian_zu?t=$time&sign=$md5_sum" -o /tmp/tongzu_zt &>/dev/null
                if [ "$(cat /tmp/tongzu_zt|grep $jiedian_zu |wc -l)" -eq "0" ];then
                                echo "$name-err-调用管理后台接口，查看本组设备状态失败。" >/tmp/tongzu_zt
                fi
        fi
}


#检查主机名和edage后台配置是否一致
function chk_edge_mess
{
	
	if [ "$(cat /tmp/tongzu_zt |grep "err-调用管理后台接口"|wc -l)" -eq "1" ];then
		echo "err-无法获取edage-admin 后台配置, 可能是设备时间不对或到edge网络异常(主机名、设备码、锐速配置信息等检查结果会***不准确***)" >>/tmp/check.log
	fi
	
	line=`cat /tmp/tongzu_zt|awk -F '}' '{for(i=1;i<=NF;i++)print $i}'|grep $name` 	
	
	if [ "$(echo "$line"|grep $name |wc -l)" -ne "1" ];then
		echo "err-无法获取edage-admin 后台配置(主机名、设备码、锐速配置信息等检查结果会***不准确***)" >>/tmp/check.log
	fi	

        #1、判断 machine_id 和后台是否一致
        if [ "$(echo "$line" |grep $name|awk -F 'mid":' '{print $2}'|awk -F ',' '{print $1}' |grep '""'|wc -l)" -eq "1" ];then
                echo "$name-ok-edage-admin设备码校验无异常" >>/tmp/check.log
        else
                if [ "$(echo "$line"|awk -F 'mid":' '{print $2}' |awk -F '"' '{print $2}')" == "$(cat /etc/nginx/servconf.ini|grep machine_id|awk -F '"' '{print $2}')" ];then
                        echo "$name-ok-edage-admin后台设备码与/etc/nginx/servconf.ini中machine_id一致" >>/tmp/check.log
                else
                        echo "$name-err-edage-admin后台设备码与/etc/nginx/servconf.ini中machine_id不一致" >>/tmp/check.log
                fi
        fi

        if [ "$(echo "$line"|awk -F 'hostname":' '{print $2}' |awk -F '"' '{print $2}')" == "$name" ];then
                echo "$name-ok-edage-admin后台主机名与/etc/nginx/servconf.ini中一致" >>/tmp/check.log
        else
                echo "$name-err-edage-admin后台主机名与/etc/nginx/servconf.ini中不一致" >>/tmp/check.log
        fi

	#2、判断网卡大小是否一致（根据是否有缓存判断设置是否合理）
	edge_wk=`echo "$line"|awk -F 'bandwidth":' '{print $2}'|awk -F ',' '{print $1}'`
	edge_ip=`echo "$line"|awk -F '"ip":"' '{print $2}' |awk -F '"' '{print $1}'`
	#net_work=`/sbin/ifconfig |grep $edge_ip -B 1|awk '{print $1}'|head -n 1`
	net_work=`ip a |grep $edge_ip |awk '{print $NF}'`
	net_wk=`/sbin/ethtool $net_work|grep "Mb/s"|awk -F 'Speed: ' '{print $2}'|awk -F 'Mb/s' '{print $1}'`
	

        if [ "$edge_wk" == "$net_wk" ];then
                echo "$name-ok-edage-admin后台网卡带宽与设备上网卡 $net_work 一致" >>/tmp/check.log
        else
                # 假如edge带宽小于本机网卡带宽，怎需要判断下是否因为设备自身配置太低导致权重偏低
                if [ "$edge_wk" -lt "$net_wk" ];then
                        if [ "$(lscpu |grep 'CPU(s)'|head -n 1 |awk '{print $NF}')" -gt "15" ] && [ "$(free -g |grep Mem|awk '{print $2}')" -gt "60" ];then
                                echo "$name-err-edage-admin后台网卡带宽与设备上网卡 $net_work 不一致, 正确网卡带宽为: $net_wk" >>/tmp/check.log
                        fi
                fi
        fi
	

	#3、判断同组内网ip是否全部都通
	nei_ip=`cat /tmp/tongzu_zt|awk -F '}' '{for(i=1;i<=NF;i++)print $i}'|grep '"up":1' |awk -F '"innerip":"' '{print $2}' |awk -F '"' '{print $1}'|grep -v '^$'`
	for ip in $nei_ip
		do
			ping -A -c 20 $ip &>/tmp/nwping.log
			diubao=`cat /tmp/nwping.log|tail -n 2|head -n 1 |awk -F '% packet loss' '{print $1}'|awk -F ', ' '{print $NF}'`
                        yanshi=`cat /tmp/nwping.log|tail -n 1|awk -F '=' '{print $2}'|awk -F '/' '{print $2}'`
			if [ "$diubao" -gt "0" ] || [ "$(echo "$yanshi"|awk '{print $1*100}'|awk -F '.' '{print $1}')" -gt "500" ];then
				echo "$name-err-到内网ip $ip 有延时或丢包,丢包率为：$diubao   延时为 $yanshi" >>/tmp/check.log
			fi 

			# 针对每个内网ip进行一次数据下载(防止防火墙8000没加白名单的情况)
			curl -x $ip:8000  http://monitor.yfcdn.net/monitor/favicon.ico -o /dev/null -w %{time_total}" "%{http_code} -v -H "Oct-host: v5.yfcdn.net" &>/tmp/0.0.0.0.log
			time_total=`cat /tmp/0.0.0.0.log|tail -n 1 |awk '{print $1}'`
			http_code=`cat /tmp/0.0.0.0.log|tail -n 1 |awk '{print $2}'`
			#假如状态码非 200，或者用时超过2s，则报错
			if [ "$(cat /tmp/0.0.0.0.log|tail -n 1 |awk '{print $1*1000}' |awk -F '.' '{print $1}')" -gt "2000" ] || [ "$(cat /tmp/0.0.0.0.log|tail -n 1 |awk '{print $2}')" != "200" ];then
				echo "$name-err-绑定同组 $ip 的8000端口下载异常，请检查 $ip 的防火墙是否添加异常或者oct是否存活" >>/tmp/check.log
			fi

		done

	#4、判断当前主机名是否和 config_lua 一致
	name_zu=`echo "$name"|cut -c 1-7`
	config_lua=`cat /opt/app/edge/etc/config.lua|grep myNode |awk -F 'myNode = ' '{print $2}' |cut -c 2-8`
	if [ "$name_zu" != "$config_lua" ];then
		echo "$name-err-当前主机名组与 /opt/app/edge/etc/config.lua 中配置不一致" >>/tmp/check.log
	fi

	#5、判断是否配置内网ip
 	nei_ip=`echo "$line"|awk -F '"innerip":"' '{print $2}' |awk -F '"' '{print $1}'|grep -v '^$'`
	if [ "$(echo "$line"|awk -F '"innerip":"' '{print $2}' |awk -F '"' '{print $1}'|grep -v '^$'|wc -l)" -eq "0" ];then
		echo "$name-err-设备edage-admin后台未配置内网ip，请检查加上" >>/tmp/check.log
	else
		#if [ "$(/sbin/ifconfig |grep "inet" |grep $nei_ip|wc -l)" -ge "1" ];then
		if [ "$(ip a |grep "inet" |grep $nei_ip|wc -l)" -ge "1" ];then
			echo "$name-ok-设备edage-admin后台配置了内网ip，并且配置无异常" >>/tmp/check.log
		else
			echo "$name-err-设备edage-admin后台配置了内网ip，但是配置异常" >>/tmp/check.log
		fi
	fi
	
	#6、判断同组设备是为同一个网段
        wang_duan_zu=`cat /tmp/tongzu_zt|awk -F '}' '{for(i=1;i<=NF;i++)print $i}'|grep '"up"'|awk -F '"innerip":"' '{print $2}'|awk -F '"' '{print $1}'|awk -F '.' '{print $1,$2,$3}'|sort -nr|uniq -c |wc -l`
        if [ "$wang_duan_zu" -gt "1" ];then
                echo "$name-info-设备同组之间ip存在多个网段($wang_duan_zu)个网段，请注意防火墙规则是否正确" >>/tmp/check.log
        fi
	
	#7、检查设备是否有被挖矿
	if [ "$(ps aux|egrep "qW3xT|ddgs" |grep -v grep  |wc -l)" -gt "1" ];then
		echo "$name-err-设备可能被黑，存在挖矿程序，请排查处理(处理方法参照：curl -s ospf.yunfancdn.com/wk.txt -x v11.yfcdn.net:80) !!!" >>/tmp/check.log
	fi

}


#检查重要服务的版本模块
function chk_version
{
	#获取各个版本的信息情况
	#检查各个版本信息
	wget -S 'ospf.yunfancdn.com/banben.list' -O /tmp/banben.list -t 2 -T 5 -e http-proxy=v5.yfcdn.net &>/dev/null
	if [ ! -f /tmp/banben.list ];then
		echo "$name-err-未能获取到各个版本的相关信息" >>/tmp/check.log
	else
		cat /tmp/banben.list |grep -v "^$" |egrep -v 'json_num|crontab|version' |grep -v "#" |grep -v dns.sh > /tmp/check_version.list
		while read line
			do
				soft=`echo "$line" |awk '{print $1}'`
				version=`echo "$line"|awk '{print $2}'`
				if [ "$(/bin/rpm -qi $soft |grep "$version" |wc -l)" -gt "0" ];then
					echo "$name-ok-$soft 版本无异常，当前版本为 $version" >>/tmp/check.log
				else
					ban_ben=`/bin/rpm -qi $soft|grep ${soft}-|awk '{print $NF}'`
					echo "$name-err-$soft 版本异常，当前版本不为 $version,当前版本为: $ban_ben" >>/tmp/check.log
				fi
			done < /tmp/check_version.list

	        #检查计划任务数目是否一致
        	cron_num=`cat /tmp/banben.list|grep -v "#"|grep crontab |awk '{print $2}'`
       		local_cron=`cat /var/spool/cron/root|grep -v "^$" |grep -v "#"|wc -l`

        	if [ "$cron_num" -ne "$local_cron" ];then
                	echo "$name-err-计划任务数目与标准不一致，本机计划任务数目为 $local_cron 标准计划任务数目为 $cron_num" >>/tmp/check.log
        	else
                	echo "$name-ok-计划任务数目与标准一致" >>/tmp/check.log
        	fi

                # 检查check脚本是否为最新版本
                if [ "$(cat /tmp/check.log |head -n 1|awk -F 'v' '{print $2*10}')" -lt "$(cat /tmp/banben.list|grep version|awk '{print $NF}'|awk -F 'v' '{print $2*10}')" ];then
			#wget -S 'ospf.yunfancdn.com/check.sh' -e http-proxy=v11.yfcdn.net -t 2 -T 5 -O /data/script/check.sh &>/dev/null
                        echo "$name-err-check脚本不是最新,更新请执行sudo wget -S 'ospf.yunfancdn.com/check.sh' -e http-proxy=v11.yfcdn.net -O /data/script/check.sh更新脚本" >>/tmp/check.log
                fi

		json_num=`cat /tmp/banben.list|grep -v "#"|grep json_num|awk '{print $2}'`
		local_json_num=`cat /etc/nginx/nginx.conf|grep cutter_log_format -A 200 |grep '\"' |wc -l`

		if [ "$local_json_num" -ne "$json_num" ];then
			echo "$name-err-nginx.conf中json日志字段与标准数目不一致，本机数目为 $local_json_num 标准数目为 $json_num" >>/tmp/check.log
		fi

		if [ "$(cat /etc/nginx/conf.d/default.conf |grep yf_balancer|wc -l)" -ne "1" ] || [ "$(cat /etc/nginx/nginx.conf |grep yf_balancer|wc -l)" -ne "1" ];then
			echo "$name-err-nginx配置中 nginx.conf 或者 default.conf 里 yf_balancer 字段配置错误" >>/tmp/check.log
		fi


	fi

	#检查计划任务里面的脚本是否都存在
        jiaoben=`cat /var/spool/cron/root|egrep -v "^#|^$"|awk -F '>' '{print $1}'|awk -F '&' '{print $1}'|awk '{print $NF}'|egrep '\.sh|\.pl|\.py'`
        for i in $jiaoben
                do
                        if [ ! -f $i ];then
                                echo "$name-err-计划任务中的脚本$i在设备上不存在" >>/tmp/check.log
                        fi
                done
	
	#检查zabbix.conf文件里面脚本是否都存在
        cat /etc/zabbix/zabbix_agentd.conf |egrep -v "^#|^$"|grep "UserParameter="|egrep '\.sh|\.pl|\.py' >/tmp/zabbix.log
        sed -i 's/\$1//g' /tmp/zabbix.log
        sed -i 's/\$2//g' /tmp/zabbix.log
        sed -i 's/\$3//g' /tmp/zabbix.log
        sed -i 's/\$4//g' /tmp/zabbix.log
        jiao_ben=`cat /tmp/zabbix.log|awk -F ',' '{print $NF}'|awk '{print $NF}'`

        for i in $jiao_ben
                do
                        if [ ! -f $i ];then
                                echo "$name-err-/etc/zabbix/zabbix_agentd.conf中的脚本$i在设备上不存在" >>/tmp/check.log
                        fi
                done

	#针对安装ospf的设备检查ospf
        if [ "$(ip a|grep '\/32' |wc -l)" -ne "0" ] && [ -f /etc/quagga/ospfd.conf ];then
                # 检查/root/ospf.sh配置是否正确
                ospfip=`cat /root/ospf.sh |grep ifconfig|awk -F 'netmask' '{print $1}'|awk '{print $NF}'`
                ospfwk=`cat /root/ospf.sh |grep ifconfig|awk -F 'netmask' '{print $1}'|awk '{print $2}'`

                ipmess=`ip a`

                if [ "$(echo "$ipmess" |grep "${ospfip}\/32" |wc -l)" -ne "1" ];then
                         echo "$name-err-ospf.sh配置异常，请执行wget -S ospf.yunfancdn.com/install_ospf.sh -e http-proxy=v11.yfcdn.net -O /tmp/install_ospf.sh 执行脚本重新修改配置">>/tmp/check.log
                fi
                if [ "$(echo "$ipmess" |grep $ospfwk |grep "${ospfip}\/32"|wc -l)" -ne "1" ];then
                        echo "$name-err-ospf.sh配置异常，请执行wget -S ospf.yunfancdn.com/install_ospf.sh -e http-proxy=v11.yfcdn.net -O /tmp/install_ospf.sh 执行脚本重新修改配置">>/tmp/check.log
                fi
                # 检查ospf计划任务是否存在
                if [ "$(cat /etc/crontab |grep -v "^$"|grep -v "^#" |grep 'ospf.sh' |wc -l)" -eq "0" ];then
                        echo "$name-err-/etc/crontab未添加 /root/ospf.sh 的执行任务（每分钟执行一次）">>/tmp/check.log
                fi

                # 检查zabbix监控是否正常运行
                lastmess=`ls /tmp/checkospf-tmp.log --full-time |awk '{print $6,$7}'`
                lastmess_sjc=`date -d "$lastmess" +%s`
                nowtime_sjc=`date +%s`
                time_num=`echo "$nowtime_sjc $lastmess_sjc"|awk '{print $1-$2}'`
                if [ "$time_num" -gt "300" ];then
                        echo "$name-err-ospf的zabbix监控检查异常，请执行wget -S ospf.yunfancdn.com/install_ospf.sh -e http-proxy=v11.yfcdn.net -O /tmp/install_ospf.sh 执行脚本重新修改配置">>/tmp/check.log
                fi

                # 检查ospf脚本是否正常运行
                lastmess1=`cat /tmp/checkospf.log`
                lastmess_sjc1=`date -d "$lastmess1" +%s`
                nowtime_sjc1=`date +%s`
                time_num1=`echo "$nowtime_sjc1 $lastmess_sjc1"|awk '{print $1-$2}'`
                if [ "$time_num1" -gt "60" ];then
                        echo "$name-err-/root/ospf.sh计划任务执行异常，请执行wget -S ospf.yunfancdn.com/install_ospf.sh -e http-proxy=v11.yfcdn.net -O /tmp/install_ospf.sh 执行脚本重新修改配置">>/tmp/check.log
                fi


        fi


	# 检查/etc/yum.repos.d/yfcustom.repo 中 gpgcheck 是否为 1
        if [ "$(echo "$name"|grep -E 'KZJHZ1U|KJSCZ1B|KSDJN1E|KSDJN2B|KZJHZ1U'|wc -l)" -ne "1" ];then
	   if [ "$(cat /etc/yum.repos.d/yfcustom.repo |grep 'gpgcheck=1'|grep -v "^#"|wc -l)" -lt "1" ];then
		echo "$name-err-设备/etc/yum.repos.d/yfcustom.repo中gpgcheck值不是 1 ，请进行对照正常跑量设备进行修改" >>/tmp/check.log
	   fi
        fi

	# 检查 /etc/salt/minion_id 和主机名是否一致
        if [ "$(cat /etc/salt/minion_id)" != "$name" ];then
                echo "$name-err-设备/etc/salt/minion_id与hostname不一致，执行wget -S ospf.yunfancdn.com/saltid.py -e http-proxy=v5.yfcdn.net  -O /data/script/saltid.py 脚本处理" >>/tmp/check.log 
        fi


}


#检查系统的相关重要配置
function chk_system
{
	#检查是否开启了防火墙
	if [ "$(/sbin/iptables -nL|grep DROP|egrep "6379|22051|8000|5210|5211"|wc -l)" -lt "5" ] || [ "$(/sbin/iptables -nL |grep "ACCEPT" |grep "/24" |wc -l)" -lt "8" ] || [ "$(iptables -nL |grep "ACCEPT" |grep "22051" |wc -l)" -lt "4" ] || [ "$(/sbin/iptables -nL|grep ACCEPT|egrep "6379|22051|8000|5210|5211"|wc -l)" -lt "9" ];then
		echo "$name-err-防火墙添加异常，请重新检查防火墙配置(iptables -F ; sh /root/iptable.sh)" >>/tmp/check.log
	else
		ip_duan=`/sbin/ip a|grep inet|grep -v inet6|grep -v '/32'|awk '{print $2}'|awk -F '.' 'BEGIN{OFS="."}{print $1,$2,$3}'|sort -nr |uniq -c |awk '{print $2}'`
                for ip in $ip_duan
                        do
                                if [ "$(/sbin/iptables -nL|grep ACCEPT|grep $ip |wc -l)" -lt "5" ];then
                                        echo "$name-err-防火墙添加异常(未加$ip段白名单)，请重新检查防火墙配置(假如是杭州三线的内网网段，则可以忽略该报错)" >>/tmp/check.log
                                fi
                        done
	fi
	
	if [ "$(cat /etc/rc.local|grep -v "#" |grep iptable.sh|wc -l)" -ne "1" ];then
		echo "$name-err-防火墙启动脚本未添加至开机启动项目中，请检查 /etc/rc.local" >>/tmp/check.log
	fi

	if [ -f /etc/sysconfig/iptables ];then

	        if [ "$(cat /etc/sysconfig/iptables|grep DROP |wc -l)" -gt "0" ];then
        	        echo "$name-err-防火墙规则被save了，请取消其save规则（/etc/sysconfig/iptables）" >>/tmp/check.log
        	fi
	fi

	#判断系统版本是否小于 2.6.32-504
	ver_red=`/bin/uname -a|awk '{print $3}'|awk -F '-' '{print $1}'`

	if [ "$(echo "$ver_red"|awk -F '.' '{print $1$2}')" -lt "26" ];then
		echo "$name-err-当前系统版本小于 2.6.32-504 ,当前系统版本为 $ver_red" >>/tmp/check.log
	fi
	
	line=`cat /tmp/tongzu_zt|awk -F '}' '{for(i=1;i<=NF;i++)print $i}'|grep $name` 
	edge_ip=`echo "$line"|awk -F '"ip":"' '{print $2}' |awk -F '"' '{print $1}'`
        #net_work=`/sbin/ifconfig |grep $edge_ip -B 1|awk '{print $1}'|head -n 1|awk -F ':' '{print $1}'`
        net_work=`ip a |grep $edge_ip |awk '{print $NF}'`

	# 针对点播设备，判断内存、cpu硬件配置是否达标
	if [ "$(echo "$name" |cut -c 7)" != "A" ] && [ "$(echo "$name" |cut -c 7)" != "S" ] && [ "$(/usr/bin/free |grep "Mem:" |awk '{print $2}')" -lt "64000000" ];then
		echo "$name-err-设备为点播设备，但是内存小于64G" >>/tmp/check.log
	fi
	if [ "$(echo "$name" |cut -c 7)" != "A" ] && [ "$(echo "$name" |cut -c 7)" != "S" ] && [ "$(lscpu |grep 'CPU(s):' |head -n 1|awk '{print $NF}')" -lt "16" ];then
		echo "$name-err-设备为点播设备，但是CPU线程数目小于16线程" >>/tmp/check.log
	fi

	# 针对点播设备，看是否关闭了swap缓存
	if [ "$(echo "$name" |cut -c 7)" != "A" ] && [ "$(echo "$name" |cut -c 7)" != "S" ] && [ "$(free |grep Swap |awk '{print $2}')" -gt "1" ];then
		echo "$name-err-设备为点播设备，但是开启了swap缓存(会严重影响cache性能),请执行 swapoff -a 关闭swap缓存" >>/tmp/check.log
	fi

	#判断是否安转锐速或者bbr或者为页面上层设备
	if [ "$(echo "$name" |cut -c 7)" != "A" ] && [ "$(echo "$name" |cut -c 7)" != "S" ] && [ "$(/usr/bin/free |grep "Mem:" |awk '{print $2}')" -ge "32000000" ];then
		#判断是否安转锐速
		if [ "$(/sbin/lsmod |grep app |wc -l)" -lt "4" ] && [ ! -f "/acceplus/bin/control.sh" ];then
			if [ "$ver_red" != "4.9.0" ];then
				echo "$name-info-设备为点播设备，但是未安转锐速或者BBR" >>/tmp/check.log
				#对于未安装锐速的，提供相关信息申请license
				net_mac=`/sbin/ip a|grep $net_work -A 1|grep "ff:ff:ff:ff:ff:ff"|awk '{print $2}'|tail -n 1`
				echo "$name-info-锐速申请信息为: $edge_ip    $net_mac    $net_work" >>/tmp/check.log
				echo "$name-info-锐速一键自动安装脚本为 wget -S 'ospf.yunfancdn.com/install_ruisu.sh' -e http-proxy=v5.yfcdn.net -P /tmp/" >>/tmp/check.log
			else
				if [ "$(/sbin/lsmod |grep tcp_bbr|wc -l)" -ne "1" ] && [ ! -f "/acceplus/bin/control.sh" ];then
					echo "$name-err-设备已经安装BBR，但是未启用BBR（/sbin/lsmod |grep bbr）" >>/tmp/check.log
				else
					echo "$name-ok-设备为点播设备并且已经安装启用了BBR" >>/tmp/check.log
				fi
			fi
		else
			#设备已安装锐速，判断锐速的相关配置是否正常
        		net_wk=`/sbin/ethtool $net_work|grep "Mb/s"|awk -F 'Speed: ' '{print $2}'|awk -F 'Mb/s' '{print $1}'`
			
			app_wk=`/appex/bin/lotServer.sh status|grep accif|awk '{print $2}'`
			in_wk=`/appex/bin/lotServer.sh status|grep wankbps|awk '{print $2}'`
			out_wk=`/appex/bin/lotServer.sh status|grep waninkbps|awk '{print $2}'`
		
			#判断加速网卡名称是否正确
			#假如无法获取到本机edge相关信息，则不检查这一步
			if [ "$(cat /tmp/tongzu_zt|wc -l)" -gt "0" ];then 
			
				if [ "$net_work" != "$app_wk" ] || [ "$(echo "$net_wk"|awk '{print $1*1000}')" != "$in_wk" ] || [ "$(echo "$net_wk"|awk '{print $1*1000}')" != "$out_wk" ];then
					echo "$name-info-设备已安装锐速，但是锐速未开启或配置异常，请检查相关配置（不需要开启则忽略此信息）" >>/tmp/check.log
					echo "$name-info-锐速,设备网卡 $net_work 设备网卡带宽: $net_wk Mb/s  锐速加速网卡: $app_wk 锐速加速带宽限制: $out_wk kb/s" >>/tmp/check.log
				else
					echo "$name-ok-设备已安转锐速并且配置都正常。设备网卡: $net_work 设备网卡带宽: $net_wk Mb/s  锐速加速网卡: $app_wk 锐速加速带宽限制: $out_wk kb/s" >>/tmp/check.log
				fi
			fi
		fi
	else
		echo "$name-ok-设备为页面设备无需安转锐速或者BBR" >>/tmp/check.log
				
	fi	

	
        #不管是否有异常都执行软中断脚本
        /bin/sh /data/script/LBcpu-nic.sh $net_work

	#判断是否有进行软中断优化操作
        log="/var/log/lbcpu-nic.log";
        CPU=$((`cat /proc/cpuinfo |grep processor|wc -l`));
        VEC=$(($CPU - 1));
        RX_NUM=$((2 ** $CPU - 1)) 
        wk_num=`printf "%X" $RX_NUM |awk '{printf("%d\n",strtonum("0x"$1))}'`   
	echo '' >/tmp/wk_num.tmp
        
        for x in `find   /sys/class/net/${net_work}/queues/* -name rx-*`
                do
                        if [ "$(cat $x/rps_cpus |awk '{printf("%d\n",strtonum("0x"$1))}')" != "$wk_num" ];then
                                echo "$name-err-设备没有进行软中断优化，请执行 sh /data/script/LBcpu-nic.sh $net_work 进行操作(执行命令即可，再有报警可以忽略)" >>/tmp/wk_num.tmp
                        fi
                done  

	if [ "$(cat /tmp/wk_num.tmp |wc -l)" -gt "1" ];then
                cat /tmp/wk_num.tmp |tail -n 1 >>/tmp/check.log
        fi


}



function check_key
{
	#use_kt检查
	if [ "$(cat /opt/app/edge/etc/config.lua|grep "use_kt = true," |wc -l)" -ne "1" ];then
		echo "$name-err-/opt/app/edge/etc/config.lua中use_kt字段配置有误" >>/tmp/check.log
	fi
	#检查sshd服务是否开启了禁用dns
	if [ "$(cat /etc/ssh/sshd_config|grep UseDNS|grep -v "^#"|grep no|wc -l)" -lt "1" ];then
		echo "$name-err-/etc/ssh/sshd_config中未配置 UseDNS no" >>/tmp/check.log
	fi
	#检查ops服务是否启动
	if [ "$(netstat -npl|grep ops |wc -l)" -lt "2" ];then
		/usr/local/agents/control start &>/dev/null
		echo "$name-err-设备ops服务未启动" >>/tmp/check.log 
	fi
	#判断是否有配置上层
	wget -S 'ospf.yunfancdn.com/upstream.list' -O /tmp/upstreamchk.list -e http-proxy=v5.yfcdn.net -t 2 -T 5 &>/dev/null
	name_zu=`echo "$name"|cut -c 1-7`
	if [ "$(cat /tmp/upstreamchk.list|awk -F '{' '{for(i=1;i<=NF;i++)print $i}' |grep '"local":"'$name_zu'"'|wc -l)" -ne "1" ];then
		echo "$name-err-设备在edge管理后台里面未添加上层" >>/tmp/check.log 
	else
		echo "$name-ok-设备在edge管理后台里面已添加上层" >>/tmp/check.log	
	fi
	#检查是否开启了日志上传
	if [ "$(cat /etc/nginx/servconf.ini |grep enable_transport|grep true |wc -l)" -ne "1" ];then
		echo "$name-err-设备未开启ops日志上传(/etc/nginx/servconf.ini中enable_transport不为true)" >>/tmp/check.log
	fi
	#检查upload_json.sh脚本是否正确
	if [ "$(cat /root/upload_json.sh|wc -l)" -ne "66" ];then
		echo "$name-err-/root/upload_json.sh 脚本异常" >>/tmp/check.log
	fi
	#检查chk_kt_sync.sh脚本是否正确
	if [ "$(cat /data/script/chk_kt_sync.sh |wc -l)" -lt "13" ];then
		echo "$name-err-/data/script/chk_kt_sync.sh脚本异常" >>/tmp/check.log
	fi 
	#检查zabbix.conf文件是否异常
	if [ "$(cat /etc/zabbix/zabbix_agentd.conf |grep ^UserParameter|wc -l)" -lt "31" ];then
		echo "$name-err-/etc/zabbix/zabbix_agentd.conf文件异常" >>/tmp/check.log
	fi
	#检查时间是否异常
	duan_time=`rdate -p time.nist.gov |awk '{print $3,$4,$5,$6,$7}'|grep 201`
        if [ "$(echo $duan_time|grep 201|wc -l)" -ne "1" ];then
                wget -t 1 -T 5 -S 'ospf.yunfancdn.com/shijian.list' -e http-proxy=v5.yfcdn.net -O /tmp/shijian.list &>/dev/null
                bz_time=`cat /tmp/shijian.list|head -n 1`
        else
                bz_time=`date -d "$duan_time" +%s`
        fi
        local_time1=`date +%s`
	local_time=`echo "$local_time1"|awk '{print $1+10}'`

        #假如本地时间戳小于网络服务器时间戳,直接报错
	#允许有10s差距
	
        if [ "$local_time" -lt "$bz_time" ];then
                echo "$name-err-本地时间小于远程服务器时间，请进行时间同步" >>/tmp/check.log
        else
                #假如本地时间戳大于或等于网络时间戳，则判断其差距是否超过 60s，超过则报错
                cha_time=`echo "$local_time $bz_time"|awk '{print $1-$2}'`
                if [ "$cha_time" -gt "80" ];then
                        echo "$name-err-本地时间大于远程服务器时间，请进行时间同步" >>/tmp/check.log
                fi
        fi
	#检查/opt/app/edge/etc/config.lua里的edge_config等key
	if [ "$(cat /opt/app/edge/etc/config.lua|egrep 'edge = edge_config|origin = origin_config|edge_config = pcall|origin_config = pcall'|wc -l)" -ne "4" ];then
		echo "$name-err-/opt/app/edge/etc/config.lua里edge_config等key配置异常，详细请参考同系统版本的正常设备" >>/tmp/check.log
	fi

	#检查kt状态是否正确
        #KT所有ip列表
        kt_server=(
        114.215.242.199
	124.232.176.65
	111.47.229.139
	111.48.61.200
        121.199.30.61
	118.25.70.58
	118.25.72.19
        115.231.99.179
        101.251.145.107
        112.13.166.74
	42.81.55.36
        121.31.30.122
        60.217.32.98
	183.129.161.77
	101.251.147.7
	112.13.172.88
	115.181.81.157
	111.48.32.200
	111.32.140.39
	124.239.147.206
	117.139.143.140
	218.98.24.37
	111.19.139.10
	222.186.170.172
	150.138.213.20
	42.48.1.141
	183.66.66.149
	222.186.170.179
	119.6.239.140
        163.177.48.228
        183.134.68.145
        106.120.176.26
        112.25.76.166
        123.157.129.151
        124.14.16.6
        121.14.159.34
        157.255.159.9
        112.54.205.247
        36.99.17.1
	60.5.252.36
        221.228.226.106
        222.138.0.242
	121.14.159.55
	121.14.159.50
	221.194.141.14
	183.134.68.155
	220.194.247.160
	183.232.214.140
	42.81.52.36
	150.138.213.20
	36.99.17.11
	119.6.239.140
	220.194.69.101
	119.6.239.140
	kt.edge.yfcdn.net
	kt.origin.yfcdn.net
        )
        kt_ip=`cat /etc/init.d/ktserver |grep "masterhost=" |head -n 1|awk -F '=' '{print $NF}'`
        if [ "$(echo ${kt_server[*]}|grep $kt_ip|wc -l)" -ne "1" ];then
                echo "$name-err-/etc/init.d/ktserver里kt中层ip配置有误，请重新检查" >>/tmp/check.log
        fi
        if [ "$(/bin/sh /data/script/chk_kt_sync.sh |grep "^0$"|wc -l)" -ne "1" ];then
                echo "$name-err-KT数据同步有延时，请重新选择kt中层进行数据同步" >>/tmp/check.log
        fi

	# 检查kt数目是否有异常
        if [ "$(/bin/sh /data/script/check_kt_num.sh |grep "^0$"|wc -l)" -ne "1" ];then
                echo "$name-err-KT条目不对，请重新选择kt中层进行数据同步" >>/tmp/check.log
        fi
	
	
	#检查/etc/resolv.conf
	if [ "$(cat /etc/resolv.conf |grep -v "^#"|egrep "8.8.8.8|114.114.114.114|223.5.5.5|119.29.29.29" |wc -l)" -lt "2" ];then
		echo "$name-err-/etc/resolv.conf配置错误或者少配置了dns" >>/tmp/check.log
	fi

	#检查本机ip提供yunfandns.com的解析是否正常
        mess=`dig mgtv.yunfandns.com +tries=1 +time=2 @0.0.0.0`
        if [ "$(echo $mess |grep 'mgtv.yunfandns.com\.' |grep 'IN'|grep 'A' |wc -l)" -lt "1" ];then
                echo "$name-err-dig mgtv.yunfandns.com @0.0.0.0 解析异常" >>/tmp/check.log
        fi

	# 检查httpdns配置
	if [ "$(cat /etc/nginx/conf.d/httpdns.conf|egrep 'cdndns.yfcloud.com cdndns.yfcloud.io;' |wc -l)" -ne "1" ];then
		echo "$name-err-/etc/nginx/conf.d/httpdns.conf里少配置了域名" >>/tmp/check.log
	fi

	# 检查pcvideoyf.yfcloud.com配置
	if [ "$(cat /etc/nginx/conf.d/pcvideoyf.yfcloud.com.conf|egrep 'pcvideoyf.yfcloud.com' |wc -l)" -ne "1" ];then
		echo "$name-err-/etc/nginx/conf.d/pcvideoyf.yfcloud.com.conf无该配置文件或者配置错误" >>/tmp/check.log
	fi

	# 针对KSDJN1B、KSDJN2B、KJSWX1E、KZJNB3E 进行重要域名配置检查
	if [ "$(cat /etc/nginx/servconf.ini|egrep "KSDJN1B|KSDJN2B|KZJNB3E|KJSWX1E"|wc -l)" -gt "0" ];then
		confnum=`egrep "ltsydzd.qq.com|ugcydzd.qq.com|lmydzd.qq.com" /etc/nginx/conf.d/*.conf |grep -v cutter_log_on|wc -l`
		if [ "$confnum" -lt "1" ];then
			echo "$name-err-设备为三线设备，但是/etc/nginx/conf.d/没有加ltsydzd.qq.com|ugcydzd.qq.com|lmydzd.qq.com等关键域名配置" >>/tmp/check.log
		fi
	fi

}


function check_server
{
        #服务进程检查
        if [ "$(/bin/netstat -npl|grep nginx|egrep "443|53"|wc -l)" -lt "2" ];then
                echo "$name-err-nginx进程数目异常，可能未启动服务或监听端口不对" >>/tmp/check.log
        fi
        if [ "$(/bin/ps aux|grep yunfancdn.conf |grep -v grep|grep -v vi|wc -l)" -ne "1" ];then
                echo "$name-err-yunfancdn进程数目异常,可能起了多个进程或者未启动服务" >>/tmp/check.log
		echo "$name-info-假如为oct启动码异常导致，执行curl -d $name 115.231.99.179:666 可自动获取oct的启动码" >>/tmp/check.log
        fi
        if [ "$(/bin/netstat -npl|grep ktserver|wc -l)" -lt "2" ];then
                echo "$name-err-ktserver进程数目异常，可能为服务未启动" >>/tmp/check.log
        fi
        if [ "$(/bin/netstat -npl|grep redis|wc -l)" -lt "1" ];then
                echo "$name-err-redis进程数目异常，可能为服务未启动" >>/tmp/check.log
        fi
        if [ "$(/bin/netstat -npl|grep flash843 |wc -l)" -lt "1" ];then
                echo "$name-err-flash843进程数目异常，可能为服务未启动,执行 /usr/local/flash843/flash843 启动" >>/tmp/check.log
        fi
        if [ "$(/bin/netstat -npl|grep zabbix |wc -l)" -lt "1" ];then
                echo "$name-err-zabbix进程数目异常，可能为服务未启动" >>/tmp/check.log
        fi
	if [ "$(ps aux |grep nginx |grep master |wc -l)" -gt "1" ];then
		echo "$name-err-nginx起了多个master进程(会影响流量上报)" >>/tmp/check.log
	fi

        if [ "$(netstat -npl|grep nginx|egrep ":11080|:554|:8080|:80|:8081|:8088|:8090|:443|:3580|:3389|:3581|:8099|:1989|:53|:11080" |wc -l)" -lt "14" ];then
                netstat -npl|grep nginx|awk -F '0.0.0.0:' '{print $2}'|awk '{print $1}' >/tmp/nginx.port
                dklist="11080 554 8080 80 8081 8088 8090 443 3580 3389 3581 8099 1989 53 11080"
                for i in $dklist
                        do
                                if [ "$(cat /tmp/nginx.port|grep "^$i$" |wc -l)" -lt "1" ];then
                                        echo "$name-err-nginx少开放了 $i 端口" >>/tmp/check.log
                                fi
                        done
        fi
	
        #绑定本机curl连续访问10次，无异常则为正常（用时小于2s）
        start=1
        end=10
        until [ $start -ge $end ];
                do
                        /usr/bin/curl --connect-timeout 5 -m 5 --retry 2 -v -x 0.0.0.0:80 -o /dev/null 'http://monitor.yfcdn.net/monitor/favicon.ico' -w %{time_total}" "%{http_code} &>/tmp/0.0.0.0
                        time_total=`cat /tmp/0.0.0.0|tail -n 1 |awk '{print $1}'`
                        http_code=`cat /tmp/0.0.0.0|tail -n 1 |awk '{print $2}'`
                        #假如状态码非 200，或者用时超过2s，则报错
                        if [ "$(cat /tmp/0.0.0.0|tail -n 1 |awk '{print $1*1000}' |awk -F '.' '{print $1}')" -gt "2000" ] || [ "$(cat /tmp/0.0.0.0|tail -n 1 |awk '{print $2}')" != "200" ];then
                                echo "$name-err-绑定本机下载异常，http状态码为: $http_code  下载总用时为: $time_total,测试url: http://monitor.yfcdn.net/monitor/favicon.ico" >>/tmp/check.log
                                start=20
                        else
                                let start+=1
                        fi
                done            
        if (($start != 20));then
                echo "$name-ok-绑定本机连续下载10次，均无异常" >>/tmp/check.log
        fi

        #针对矿机，看是否有添加矿工账号密码
        if [ "$(echo "$name"|grep -v -E 'AHAPDAB|ASNAKAB|AAHMABB'|cut -c 14-14|grep "K" |wc -l)" -eq "1" ];then
                if [ "$(cat /etc/nginx/nginx.conf|grep billing_miner_info|wc -l)" -ne "1" ];then
                        echo "$name-err-设备为矿机，但是在/etc/nginx/nginx.conf中未添加矿工账号密码" >>/tmp/check.log
                fi
		#检查到矿机验证域名是否有网络异常
                ping -A -c 5 auth.yunfancdn.com &>/tmp/nwping.log               
                diubao=`cat /tmp/nwping.log|tail -n 2|head -n 1 |awk -F '% packet loss' '{print $1}'|awk -F ', ' '{print $NF}'`
                if [ "$diubao" -gt "70" ];then
                        echo "$name-err-设备为矿机，到认证域名auth.yunfancdn.com不通" >>/tmp/check.log
                fi
	fi
	
	#针对点播设备，检查是否误添加了矿工账号密码、oct挂载磁盘是否小于9个
	if [ "$(echo "$name"|grep -v -E 'AHAPDAB|ASNAKAB|AAHMABB'|cut -c 6-7|egrep "AB|BB|CB|DB|EB" |wc -l)" -ne "1" ] && [ "$(cat /etc/nginx/nginx.conf|grep billing_miner_info|wc -l)" -ne "0" ];then
                echo "$name-err-设备为点播设备，但是在/etc/nginx/nginx.conf中误添加了矿工账号密码" >>/tmp/check.log
        fi
	if [ "$(echo $name|egrep -v "^O|1A|2A|3A|1S|^K|1L|2L"|wc -l)" -eq "1" ];then
              if [ "$(curl -s http://localhost:5211/statinfo | json2lua |grep '/dev/'|wc -l)" -lt "9" ];then
                    echo "$name-err-设备为点播设备，但oct挂载裸盘数目小于9个，请排查是否有磁盘异常" >>/tmp/check.log
              fi
        fi
	#检查设备https证书是否异常
	md51=`md5sum /etc/nginx/conf.d/cert/yfcloud.crt|awk '{print $1}'`
	md52=`md5sum /etc/nginx/conf.d/cert/yfcloud.key|awk '{print $1}'`
	if [ $md51 != 8309f3c8ea405da7990e1c27b83361a9 ] || [ $md52 != c16afd44d7075aa9e06b59b5065edbc6 ] ;then
		wget -S 'ospf.yunfancdn.com/yfcloud.crt' -e http-proxy=v11.yfcdn.net -O /etc/nginx/conf.d/cert/yfcloud.crt &>/dev/null
		wget -S 'ospf.yunfancdn.com/yfcloud.key' -e http-proxy=v11.yfcdn.net -O /etc/nginx/conf.d/cert/yfcloud.key &>/dev/null
		echo "$name-err-/etc/nginx/conf.d/cert/ 下证书不正确" >>/tmp/check.log
	fi

	#检查设备上传json脚本md5
	md53=`md5sum /root/check_json_upload.sh|awk '{print $1}'`
	if [ $md53 != d1d282aa7f4bfa34bd5ba4e0bd4e6e51 ];then
		echo "$name-err-/root/check_json_upload.sh脚本不正确" >>/tmp/check.log
	fi

	echo '5211,5210' >/proc/sys/net/ipv4/ip_local_reserved_ports

        #检查nginx或者oct配置的线程数目是否正确
        cpunum=`lscpu |grep "CPU(s): "|head -n 1|awk '{print $2}'`
        thrnum=`echo "$cpunum"|awk '{print $1-1}'`
        ngxnum=`cat /etc/nginx/nginx.conf |grep worker_processes |awk -F '[ ;]' '{print $(NF-1)}'`
        octnum=`cat /etc/yunfancdn.conf|grep threads |awk '{print $2}'`
	#只检查点播设备
	if [ "$(echo $name|egrep -v "^O|1A|2A|3A|1S|^K|1L|2L|1T|2T|^YZJ|^YBJ|ASCCDAB"|wc -l)" -eq "1" ];then
        	if [ "$thrnum" != "$ngxnum" ] || [ "$octnum" -lt "11" ];then
                	echo "$name-err-nginx或者oct配置的线程使用数目不对" >>/tmp/check.log
        	fi
	fi

        #检查大内存(内存 > 90G)设备oct中使用内存是否设置合理
        if [ "$(free -g|grep Mem|awk '{print $2}')" -gt "120" ];then
                #内存大于 120G 的设备，oct设置内存要 > 100G < 110G
                if [ "$(cat /etc/yunfancdn.conf |grep max_io_buffer|grep -v "^#"|awk '{print $NF}')" -gt "112640" ] || [ "$(cat /etc/yunfancdn.conf |grep max_io_buffer|grep -v "^#"|awk '{print $NF}')" -lt "102400" ];then
                        echo "$name-err-/etc/yunfancdn.conf中max_io_buffer配置不合理(该设备合理值为110592)" >>/tmp/check.log
                fi
        else
                if [ "$(free -g|grep Mem|awk '{print $2}')" -gt "90" ];then
                        #内存大于 90G 的设备，oct设置内存要 > 60G < 75G
                        if [ "$(cat /etc/yunfancdn.conf |grep max_io_buffer|grep -v "^#"|awk '{print $NF}')" -gt "76800" ] || [ "$(cat /etc/yunfancdn.conf |grep max_io_buffer|grep -v "^#"|awk '{print $NF}')" -lt "61440" ];then
                                echo "$name-err-/etc/yunfancdn.conf中max_io_buffer配置不合理(该设备合理值为65536)" >>/tmp/check.log
                        fi
                fi
        fi

	#检查小内存设备(内存 < 32G)设备oct中使用内存+item_delay_close是否设置合理
	if [ "$(free -g|grep Mem|awk '{print $2}')" -gt "30" ] && [ "$(free -g|grep Mem|awk '{print $2}')" -lt "40" ];then
		#内存 30 - 40G 之间的设备
		if [ "$(cat /etc/yunfancdn.conf |grep max_io_buffer|grep -v "^#"|awk '{print $NF}')" -gt "24576" ] || [ "$(cat /etc/yunfancdn.conf |grep max_io_buffer|grep -v "^#"|awk '{print $NF}')" -lt "12288" ];then 
			echo "$name-err-/etc/yunfancdn.conf中max_io_buffer配置不合理(该设备合理值为16384)" >>/tmp/check.log
		fi
		if [ "$(cat /etc/yunfancdn.conf |grep item_delay_close|grep -v "^#"|awk '{print $NF}')" -gt "60" ] || [ "$(cat /etc/yunfancdn.conf |grep item_delay_close|grep -v "^#"|awk '{print $NF}')" -lt "30" ];then
			echo "$name-err-/etc/yunfancdn.conf中item_delay_close配置不合理(该设备合理值为60)" >>/tmp/check.log
		fi
	fi

	if [ "$(free -g|grep Mem|awk '{print $2}')" -gt "20" ] && [ "$(free -g|grep Mem|awk '{print $2}')" -lt "30" ];then
                #内存 20 - 30G 之间的设备
                if [ "$(cat /etc/yunfancdn.conf |grep max_io_buffer|grep -v "^#"|awk '{print $NF}')" -gt "16384" ] || [ "$(cat /etc/yunfancdn.conf |grep max_io_buffer|grep -v "^#"|awk '{print $NF}')" -lt "8192" ];then
                        echo "$name-err-/etc/yunfancdn.conf中max_io_buffer配置不合理(该设备合理值为12288)" >>/tmp/check.log
                fi
                if [ "$(cat /etc/yunfancdn.conf |grep item_delay_close|grep -v "^#"|awk '{print $NF}')" -gt "60" ] || [ "$(cat /etc/yunfancdn.conf |grep item_delay_close|grep -v "^#"|awk '{print $NF}')" -lt "30" ];then
                        echo "$name-err-/etc/yunfancdn.conf中item_delay_close配置不合理(该设备合理值为60)" >>/tmp/check.log
                fi
        fi

	if [ "$(free -g|grep Mem|awk '{print $2}')" -lt "20" ];then
                #内存 20 - 30G 之间的设备
                if [ "$(cat /etc/yunfancdn.conf |grep max_io_buffer|grep -v "^#"|awk '{print $NF}')" -gt "10240" ] || [ "$(cat /etc/yunfancdn.conf |grep max_io_buffer|grep -v "^#"|awk '{print $NF}')" -lt "2000" ];then
                        echo "$name-err-/etc/yunfancdn.conf中max_io_buffer配置不合理(该设备合理值为8192或以下)" >>/tmp/check.log
                fi
                if [ "$(cat /etc/yunfancdn.conf |grep item_delay_close|grep -v "^#"|awk '{print $NF}')" -gt "60" ] || [ "$(cat /etc/yunfancdn.conf |grep item_delay_close|grep -v "^#"|awk '{print $NF}')" -lt "30" ];then
                        echo "$name-err-/etc/yunfancdn.conf中item_delay_close配置不合理(该设备合理值为60)" >>/tmp/check.log
                fi
        fi

        #检查oct最大空闲内存数值是否设置正确
        if [ "$(cat /etc/yunfancdn.conf |grep mem_reserve|grep -v "^#"|awk '{print $NF}')" -ne "5120" ];then
                echo "$name-err-/etc/yunfancdn.conf中mem_reserve配置不正确，正确值为5120" >>/tmp/check.log
        fi
	
	#检查nginx的monitor.conf是否正确
	if [ "$(cat /etc/nginx/conf.d/monitor.conf |egrep "/oct|domaininfo" |wc -l)" -lt "4" ];then
		echo "$name-err-/etc/nginx/conf.d/monitor.conf该配置文件不标准，请参照线上正常配置" >>/tmp/check.log
	fi

}


function check_zabbix
{
	curl --connect-timeout 5 -m 5 --retry 2 -H 'Content-Type:application/json' -d '{"jsonrpc":"2.0","method":"host.get","params":{"output":"extend","filter": {"host": ["'$name'"]}},"auth":"87343f5ec7c85637c34d45b28a9dfa36","id":1 }' http://cdn1.zabbix.yfcdn.net/api_jsonrpc.php -o /tmp/chk_zabbix &>/dev/null
        zabb_zt=`cat /tmp/chk_zabbix |awk -F ',' '{for(i=1;i<=NF;i++)print $i}'|grep '^"status":"0"'|wc -l`
        if [ "$zabb_zt" == "1" ];then
                echo "$name-ok-设备zabbix监控为启用状态" >>/tmp/check.log
        else
                echo "$name-err-设备zabbix监控未添加或者为禁用状态或者主机名错误" >>/tmp/check.log
        fi

}


#功能选择模块
if [ "$1" == "-h" ] || [ "$1" == "--help" ];then
        cat /tmp/check.log
        help
else
	get_tongzu_zt
	chk_edge_mess
	chk_version
	chk_system
	check_key
	check_server
	check_zabbix
	cat /tmp/check.log
fi

