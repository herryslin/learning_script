#!/bin/bash
#initial yfcloud soft and system env
#author by zrw 20160821 1st
#modify by bxf 20160906 2st
#modify by bxf 20160907. add  bashrc & dmesg timestamp
#modify by zrw 20160923 add grep system disk then ignore it

###yum
#Centos-7.repo  epel-7.repo  yfcustom.repo
###our tools
#hitnet log_util cpanm 

###base tools
#bind-utils sysstat perl-devel gcc mtr traceroute iputils glibc.i686 lrzsz iftop ntpdate libselinux-python screen htop iftop openssl-devel perl-ExtUtils-CBuilder net-snmp net-snmp-utils unzip vim

###script
#root dir
#check_cdn.sh check_json_upload.sh cut_billing_log.sh cut_nginx_log.sh del_log.sh ktserver_monitor.sh netif.sh
#data script
#cdn.logrotate chk_kick.py chk_kt_sync.sh chk_upstream_conn.py find_disk.sh tcp_status.sh

###package
#lua-edge yunfancdn openresty  yfutils zabbix ops-agents ktserver flash843



#pakeage name
#OCT='yunfancdn-2017.1009.1611-master.el6.x86_64.rpm'
#EDGE='lua-edge-20171016-1638.master.noarch.rpm'
#NGX='openresty-1.11.7.1-62_master.el7.centos.x86_64.rpm'
OCT='yunfancdn-2018.0827.1752-master.el6.x86_64'
EDGE='lua-edge-20181107-1131.master.noarch'
NGX='openresty-1.13.6.2rc1-81.1_master.el7.centos.x86_64'
ZABBIX='zabbix-agent-3.2.3-1.el7.x86_64.rpm'
KTSERVER='kyotocabinet-20160122-1.x86_64.rpm kyototycoon-20160121-1.x86_64.rpm'
OTHER='luajit-2.0.4-2.el6.x86_64.rpm lua-cjson-2.1.0-1.el6.x86_64.rpm '
OPENRESTYSSL='yf-openresty-openssl-1.0.2j-1.el7.centos.x86_64.rpm'
REDIS='redis-3-2.9.el7.centos.x86_64.rpm'
IPDATX='ipdatx-0.1-5.noarch'
YFETCD='yf-etcd-2018.0418.1045-master.el6.x86_64'
YFETCDINFO='yf-etcd-debuginfo-2018.0323.1136-master.el6.x86_64'



#Hostname
#while true; do
#	read -p "please enter this machine hostname: " hostname
#	len=`echo $hostname | wc -L`
#
#	if [ ! -z $hostname -a $len -eq 14 ]; then
#		break
#	else
#		echo "wrong Hostname"
#	fi
#done
{% for host in groups['all'] %}
{% if host in ansible_all_ipv4_addresses %}
hostname={{data[host]}}
{% endif %}
{% endfor %}


##set  time zone
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

#CPU_CORE
CPU_CORE=`cat /proc/cpuinfo | grep CPU | wc -l`

function initial_sys() {
	echo "##########Initial system##########"

	#the use of the HOSTNAME variable in the '/etc/sysconfig/network' file is now deprecated in 7
	#use hostnamectl control hostname
	hostnamectl set-hostname $hostname
	hostnamectl --static set-hostname $hostname

	#DNS /etc/resolv.conf
	:>/etc/resolv.conf
	echo -e "nameserver 119.29.29.29\nnameserver 223.5.5.5" >/etc/resolv.conf
	#chattr +i /etc/resolv.conf

	#limits.conf
	mv -f PAK_7/limits.conf /etc/security/limits.conf
    /bin/cp -f PAK_7/sysctl.conf /etc/sysctl.conf && sysctl -p

	#bashrc profile
	mv -f PAK_7/bashrc /root/.bashrc
	mv -f PAK_7/profile /etc

	#host allow & deny
	mv -f PAK_7/hosts.deny /etc/hosts.deny
	mv -f PAK_7/hosts.allow /etc/hosts.allow

	###yum###
        rm -f /etc/yum.repos.d/*
        cp PAK_7/C*.repo  /etc/yum.repos.d/
        cp PAK_7/e*.repo    /etc/yum.repos.d/
        cp PAK_7/saltstack.repo  /etc/yum.repos.d/
        yum -y install salt-minion


	rm -f /etc/yum.repos.d/*
	cp  -rf PAK_7/*.repo /etc/yum.repos.d/
        yum -y install salt-minion

	yum -y install psmisc  cpan bind-utils sysstat perl-devel gcc mtr traceroute iputils glibc.i686 lrzsz iftop ntpdate libselinux-python screen htop bzip2 iftop openssl-devel openssh-clients perl-ExtUtils-CBuilder perl-Test-Simple perl-Test-Harness telnet lsscsi dmidecode unzip vim  net-tools rdate

    ###iptables###
	#/sbin/iptables -F
	#/etc/init.d/iptables save
	setenforce 0
	grep 'SELINUX=enforcing' /etc/selinux/config && sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

	####salt-minion#####
	cp -f PAK_7/minion /etc/salt/minion
	
	systemctl start salt-minion


	###ssh###
	mkdir -pv /root/.ssh
	mv -f PAK_7/authorized_keys /root/.ssh
	chmod 700 /root/.ssh
	chmod 600 /root/.ssh/authorized_keys
        chown root:root /root/.ssh/authorized_keys
	mv -f PAK_7/sshd_config /etc/ssh/sshd_config
	chmod 600 /etc/ssh/sshd_config
	systemctl restart sshd.service


 #   ###check.sh###
#	wget -S 'ospf.yunfancdn.com/check.sh' -e http-proxy=115.238.147.189 -O /data/script/check.sh

	###redis###
	#sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis.conf
	#wget -S 'ospf.yunfancdn.com/redis' -e http-proxy=115.238.147.189 -O /etc/init.d/redis
	#chmod o+x /etc/init.d/redis;/etc/init.d/redis start
	#/etc/init.d/redis start

    ###dmesg timestamp###
	echo Y > /sys/module/printk/parameters/time

}

function mk_f_d() {
	echo "##########create necessary dir and file##########"
	mkdir -pv /data/{kyoto,log,script,ngx_core}
	mkdir -pv /data/log/{nginx,octopus,temp}
	mkdir -pv /data/log/nginx/{billing,backup,proxy_temp}
	mkdir -pv /data/log/octopus/billing
	mkdir -pv /etc/nginx/conf.d/cert
	mkdir -pv /run/yunfancdn/
	chmod 777 /data/log/nginx/{billing,proxy_temp} /data/ngx_core
	touch /data/log/octopus/{access.log,error.log}
}

function serv() {
	echo "##########Install package##########"
	
	cd PAK_7
	yum -y install  yfutils
	#yum -y localinstall $OCT $EDGE $NGX $ZABBIX $KTSERVER $OTHER  $OPENRESTYSSL $REDIS $IPDATX
        yum -y install $OCT $EDGE $NGX $IPDATX $YFETCD $YFETCDINFO
        yum -y localinstall  $ZABBIX $KTSERVER $OTHER  $OPENRESTYSSL $REDIS 
        rpm --import rpm_public.key
	cd ..

	M=${hostname:0-1:1}
	T=${hostname:6:1}

	#whether is miner or not
	if [[ "$M" != 'K' ]]; then
		IDENT=3
	else
		IDENT=13
	fi
	
	#whether is sas or sata
	if [ "$T" = 'A' -o "$T" = 'S' ]; then
		s=15
	else
		s=75
	fi
    yum -y install bzip2
	#flash843
	tar xf PAK_7/flash843.tar.bz2 -C /usr/local/

	#ops-agent
	tar xf PAK_7/agents.tar.bz2 -C /usr/local/
	cd /usr/local/agents && ./control start
	cd -


	#ktserver
	tar zxf PAK_7/openssl.tgz -C /data/kyoto
	grep "/usr/local/lib" /etc/ld.so.conf || echo "/usr/local/lib" >> /etc/ld.so.conf
	ldconfig
	cp PAK_7/ktserver /etc/init.d/

	cp PAK_7/{kt_backup.lua,kt_partdump.lua,kt_partdump.sh,kt_timestamp.sh} /data/kyoto
	chmod 755 /data/kyoto/{kt_partdump.sh,kt_timestamp.sh}

	#while true; do
#		read -p "please enter this machine ktserver upstream: " ktmid
		
#		if [ ! -z $hostname  ]; then
#			break
#		fi
#	done
#	/etc/init.d/ktserver switch $ktmid
        /etc/init.d/ktserver switch {{data['ktserver']}}
	/etc/init.d/ktserver restart


	#appex
	#card=`/sbin/ifconfig|awk 'NR==1{print $1}'`
	#speed=`/sbin/ethtool $card|grep -i "speed"|awk '{print $2}'|cut -dM -f1`
	#cd PAK_7
	#tar xf LotServer.tar.bz2
	#sh LotServer/install.sh  -i $card -in ${speed}000 -out ${speed}000 -s 0
	###mv -f *.apx-20341231.lic /appex/etc/apx-20341231.lic
	#sed -i 's/maxmode="1"/maxmode="0"/g' /appex/etc/config
	#cd ..


	#service config

        #default.conf
        wget -S 'ospf.yunfancdn.com/baidupcs.com.conf' -e http-proxy=v11.yfcdn.net -O /etc/nginx/conf.d/baidupcs.com.conf
	mv -f PAK_7/{default.conf,default_ssl.conf} /etc/nginx/conf.d/
	if [ "$s" -eq 15 ];then
		sed -i "s/listen 80 default_server.*/listen 80 default_server;/" /etc/nginx/conf.d/default.conf
		sed -i "s/listen 443 default_server.*/listen 443 default_server ssl;/" /etc/nginx/conf.d/default_ssl.conf
	fi

        #yf-etcd
        wget -S 'ospf.yunfancdn.com/agent.conf.template' -e http-proxy=v11.yfcdn.net -O /opt/agent/conf/agent.conf.template
        wget -S 'ospf.yunfancdn.com/agent.conf.sh' -e http-proxy=v11.yfcdn.net -O /opt/agent/conf/agent.conf.sh
        cd /opt/agent && sh ./conf/agent.conf.sh
        /opt/agent/bin/agent.sh start
        cd -

        #zabbix_agentd.conf
        wget -S 'ospf.yunfancdn.com/check_graysystem_timestamp.sh' -e http-proxy=v11.yfcdn.net -O /data/script/check_graysystem_timestamp.sh
        chmod -R 755 /opt/agent/conf/
        chmod 755 /data/script/check_graysystem_timestamp.sh
        wget -S 'ospf.yunfancdn.com/check_graysystem_ktsync.sh' -e http-proxy=v11.yfcdn.net -O /data/script/check_graysystem_ktsync.sh
        chmod 755 /data/script/check_graysystem_ktsync.sh
	mv -f PAK_7/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf
	mv PAK_7/zabbix-agent /etc/init.d/

	#luaedge
	mv -f PAK_7/config.lua /opt/app/edge/etc/config.lua
	myNode=${hostname:0:7}
	sed -i "9s/.*/        myNode = '$myNode',/" /opt/app/edge/etc/config.lua

	grep  edge_config  /opt/app/edge/etc/config.lua;
	if [ $? -ne 0 ];then
		sed -i /_VERSION/a"local _, origin_config = pcall(require, \"config_origin\")" /opt/app/edge/etc/config.lua ;
		sed -i /_VERSION/a"local _, edge_config = pcall(require, \"config_edge\")" /opt/app/edge/etc/config.lua;
	fi
	sed -i "s/edge = require(\"config_edge\")/edge = edge_config/g" /opt/app/edge/etc/config.lua 
	sed -i "s/origin = require(\"config_origin\")/origin = origin_config/g" /opt/app/edge/etc/config.lua

	#/etc/nginx/servconf.ini
	sed -i "s/hostname.*/hostname = \"$hostname\"/" /etc/nginx/servconf.ini
	SerialNumber=`/usr/sbin/dmidecode -t1 | grep 'Serial Number' | awk '{print $NF}'`
	#sed -i "s/machine_id =.*/machine_id = \"$SerialNumber\"/" /etc/nginx/servconf.ini
	sed -i "s/machine_id =.*/machine_id = \"$hostname\"/" /etc/nginx/servconf.ini
	sed -i "s/enable_transport =.*/enable_transport = true/" /etc/nginx/servconf.ini
        echo "# 开启长链推送" >> /etc/nginx/servconf.ini
        echo "enable_wsclient = true" >> /etc/nginx/servconf.ini

	#yunfancdn
	mv -f PAK_7/yunfancdn.service /usr/lib/systemd/system
	if [[ "$M" = 'K' ]]; then
		sed -i 's@ExecStart.*@ExecStart=/bin/yunfancdn -c /etc/yunfancdn.conf -i /run/yunfancdn/yunfancdn.pid -l 1@' /usr/lib/systemd/system/yunfancdn.service
	fi
	systemctl daemon-reload
	#OCT ignore system disk
	system_disk=`lsblk  | egrep '/boot$' | awk '{print $1}' | egrep -o '[a-z]*'`
	store=`lsblk -d | sed '1d' | grep -Ev "$system_disk|sr"|awk '{print "path"" /dev/"$1}'|sort -k 2`

        #OCT mem
	mem_oct=`free -g | tr [:blank:] \\\n | grep [0-9] | sed -n '1p'`
        if [[ $mem_oct -ge 120 ]];then
		max_io_buffer=110592
	elif [[ $mem_oct -ge 90 && $mem_oct -le 119 ]];then
		max_io_buffer=65536
        else
            	max_io_buffer=49152
        fi


	:>/etc/yunfancdn.conf
	cat >>/etc/yunfancdn.conf<<EOF
threads $[$CPU_CORE-1]
store lvdata
$store
direct_io on
item_delay_close 150
max_io_buffer $max_io_buffer
mem_reserve 5120
meta_dump_path /var/yunfancdn/meta_dump_path
error_log /data/log/octopus/error.log
dns_nameservers 119.29.29.29 223.5.5.5
set_log_level error
worker_ident $IDENT 
serial_num 76b940a769F8d9d3eaf875602C99fb0e7ba1ace3

listen 8000
################retry#################
upstream_host_bak 3,504 503 502
########upstream#########
dns_nameservers 119.29.29.29 223.5.5.5
customize_upstream_host_value_by_request_header Custom-Host
######store######
description default
order_of_store lvdata
######Oct header#######
oct_host on
oct_control_header  on
oct_header_ignore Oct-Ignore-Header
force_accept_ranges_none_by_request_header Oct-Accept-Ranges-None
#####https#########
upstream_ssl_verify_server_cert off
check_protocol Oct-Use-Https yes
set_ssl_version_by_request_header Oct-SSL-Version
upstream_ssl_cafile /etc/pki/tls/cert.pem
#########Log###############
access_log /data/log/octopus/access.log
billing /data/log/octopus/billing/billing_%s.log 20
upstream_log /data/log/octopus/upstream.log
#########follow302#########
follow_redirections on
#########Timout#####################
request_header_max_size 16384
client_recv_timeout 60
client_send_timeout 60
upstream_recv_timeout 60
upstream_send_timeout 60
client_keepalive_timeout 60
upstream_keepalive_timeout 60
upstream_connect_timeout 2
################################
key_include_query off
key_include_host on
expires_header Oct-Max-Age
mp4 mp4 start end second
flv flv start end byteAV
ts ts octend second 0
tsv2 ts octend sample-drag 0
default_normalize_encoding gzip
offline_mode on
check_consistency off
enable_key_rewrite_by_whitelist on
response_debug_info on
upstream_pool_size 40
oct_bytes_drag oct-Bytes-Drag
sndbuf 32768
mod_mem_cache  Oct-Error-Status-Cache
mod_cc_drm Cc-Drm-V1
#########error_page#########
oct_error_page on
EOF

	#nginx conf
	:>/etc/nginx/nginx.conf
	cat >>/etc/nginx/nginx.conf<<EOF
user  nginx;
worker_processes  $[$CPU_CORE-1];

error_log  /data/log/nginx/error.log error;
pid        /var/run/nginx.pid;


events {
    worker_connections  40960;
}

worker_rlimit_nofile 40960;

worker_rlimit_core 5g;
working_directory /data/ngx_core;

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;


    cutter_log_format  log_json '{"http_host":"\$http_host", '
                                '"layer":"\$http_oct_layer", '
                                '"request_time":"\$request_time", '
                                '"upstream_response_time":"\$upstream_response_time", '
                                '"billing_ident":"\$billing_ident", '
                                '"body_bytes_sent":"\$body_bytes_sent", '
				'"header_start":"\$header_start", '
                                '"body_start":"\$body_start", '
                                '"bytes_sent":"\$bytes_sent", '
				'"fake_body_bytes_sent":"\$fake_body_bytes_sent", '
                                '"cache_hit":"\$cache_hit", '
                                '"connection":"\$connection", '
                                '"connection_requests":"\$connection_requests", '
                                '"hostname":"\$hostname", '
                                '"http_range":"\$http_range", '
                                '"http_referer":"\$http_referer", '
                                '"http_user_agent":"\$http_user_agent", '
                                '"http_x_forwarded_for":"\$http_x_forwarded_for", '
                                '"http_x_real_ip":"\$http_x_real_ip", '
                                '"remote_addr":"\$remote_addr", '
                                '"remote_user":"\$remote_user", '
                                '"method":"\$request_method", '
                                '"uri":"\$uri", '
                                '"query_string":"\$query_string", '
                                '"scheme":"\$scheme", '
                                '"sent_http_content_encoding":"\$sent_http_content_encoding", '
                                '"sent_http_content_length":"\$sent_http_content_length", '
                                '"sent_http_oct_response_info":"\$sent_http_oct_response_info", '
                                '"sent_http_x_bs_request_id":"\$sent_http_x_bs_request_id", '
                                '"server_addr":"\$server_addr", '
                                '"server_protocol":"\$server_protocol", '
                                '"status":"\$status", '
                                '"time_local":"\$time_local", '
                                '"http_origin_host":"\$http_origin_host", '
                                '"http_x_cdn_reqid":"\$http_x_cdn_reqid", '
				'"sent_http_oct_upstream":"\$sent_http_oct_upstream", '
                                '"http_x_cdn_ip":"\$http_x_cdn_ip", '
                                '"oct_worker_ident":"\$http_oct_worker_ident", '
				'"speedlimit_by_vkey_parse":"\$http_speedlimit_by_vkey_parse",'
				'"speedlimit_by_asyncfilter":"\$http_speedlimit_by_asyncfilter",'
				'"bytes":"\$http_bytes",'
                                '"log_host":"\$log_host", '
				'"sdtfrom":"\$http_sdtfrom", '
                                '"uin":"\$http_uin", '
                                '"guid":"\$http_guid", '
                                '"qq_uri":"\$http_qq_uri", '
                                '"qq_req_args":"\$http_qq_req_args", '
				'"cdn_upstream_addr":"\$http_cdn_upstream_addr",'
				'"hit_info":"\$http_hit_info",'
				'"last-modified":"\$sent_http_last_modified",'
				'"upstream_http_Date":"\$upstream_http_Date",'
				'"accept_ranges":"\$sent_http_accept_ranges", '
				'"age":"\$sent_http_age", '
				'"accept_encoding":"\$http_accept_encoding", '
				'"if_modified_since":"\$http_if_modified_since", '
				'"if_none_match":"\$http_if_none_match", '
				'"http_x_edge_error":"\$sent_http_x_edge_error", '
				'"limit_rate":"\$limit_rate", '
				'"If-Match":"\$http_if_Match",'
				'"If-Unmodified-Since":"\$http_if_Unmodified_Since",'								
				'"http_x_info_fetcher":"\$http_x_info_fetcher",'
				'"http_x_info_objsize":"\$http_x_info_objsize",'
				'"http_x_info_request_id":"\$http_x_info_request_id",'
				'"http_x_info_md5":"\$http_x_info_md5",'
				'"http_content_type":"\$sent_http_Content_Type",'
				'"http_yf-p2p-id":"\$http_yf_p2p_id",'
				'"http_P2P-Only":"\$http_p2p_only",'
				'"upstream_http_expires":"\$upstream_http_Expires",'
				'"upstream_http_Content_Length":"\$upstream_http_Content_Length",'
				'"upstream_http_Max_Age":"\$upstream_http_max_age",'
				'"upstream_age":"\$upstream_http_age",'
				'"http_dispatch_dest":"\$http_dispatch_dest",'
			        '"preload":"\$http_el_preload_tag",'
			        '"http_cookie":"\$http_cookie",'
			        '"time_local_msec":"\$msec",'
                                '"remote_port":"\$remote_port",'
                                '"billing_kv":"\$billing_kv",'
                                '"stream_session_id":"\$stream_session_id",'
                                '"stream_session_online":"\$stream_session_online",'
                                '"file_total_size":"\$http_file_total_size",'
                                '"sent_http_X_Reqid":"\$sent_http_X_Reqid",'
                                '"Use-Chunk":"\$http_Use_Chunk",'
                                '"Origin":"\$http_origin",'
                                '"Access-Control-Request-Method":"\$http_access_control_request_method",'
                                '"Access-Control-Request-Headers":"\$http_access_control_request_headers",'
                                '"yf_request_locale":"\$yf_request_locale",'
				'"request_length":"\$request_length",'
				'"lua_traceid":"\$lua_traceid",'
                                '"sent_http_from":"\$sent_http_from",'
                                '"upstream_addr":"\$upstream_addr",'
                                '"http_P2P-X-Http-User-Agent":"\$http_p2p_x_http_user_agent",'
                                '"http_P2P-X-Remote-Addr":"\$http_p2p_x_remote_addr",'
                                '"http_P2P-X-Http-Referer":"\$http_p2p_x_http_referer",'
                                '"http_P2P-X-Forwarded-For":"\$http_p2p_x_forwarded_for",'
                                '"http_P2P-X-Request-Time":"\$http_p2p_x_request_time",'
                                '"http_P2P-X-Response-Time":"\$http_p2p_x_response_time",'
                                '"http_P2P-X-Request-Body-Length":"\$http_p2p_x_request_body_length"}';

	fake_no_billing_headers p2p-only;
    server_tokens off;
    add_header YF-ID \$hostname always;
    lua_code_cache on;
    lua_shared_dict Qhost 3m;
    bodytime on;
    client_body_buffer_size 100k;
    lua_max_pending_timers 20480;
    lua_max_running_timers 8192;

    proxy_temp_path /data/log/nginx/proxy_temp 1 2;
    access_log /data/log/nginx/access.log main;

    billing on;
    billing_file /data/log/nginx/billing/billing.log;
    billing_by_url off;
    billing_worker_ident $IDENT;
    billing_flow_by_log on;
    stream_session on;

    server_names_hash_max_size 512;
    server_names_hash_bucket_size 192;
    large_client_header_buffers 4 16k;
    client_header_buffer_size 2k;

    sendfile        on;
    tcp_nopush     off;
    lingering_close   on;
    lingering_timeout 500ms;

    keepalive_timeout  $s;

    limit_conn_zone \$binary_remote_addr zone=yfcdn:10m;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}
include /etc/nginx/conf.d/stream.config;
EOF
}



function cp_file() {
	echo "##########copy file##########"
	#root dir script
	for i in check_cdn.sh check_json_upload.sh cut_billing_log.sh cut_nginx_log.sh del_log.sh ktserver_monitor.sh netif.sh upload_json.sh log_util.pl nginx_access.sh upload_db_json.sh; do
		cp PAK_7/$i /root/
		chmod 755 /root/$i
	done

	#data dir script
	for i in saltprocess.py saltkey.py check_octcpu.sh check_oct_top.sh cut_oct_access.sh cut_nginx_err.sh check_octbilling.py jiuwu.sh chk_oct_total_conn.py ping.pl send_qqmail.pyc chk_kick.py chk_kt_sync.sh chk_net_card.sh chk_upstream_conn.py find_disk.sh ngx_status.sh tcp_status.sh octapi.py oct_store.sh http_code_billing.pl refreshdns.pl domainlist local_dns.txt LBcpu-nic.sh get_servertime.sh check_config.sh check_slow.sh chk_iptable.sh check_ruisu_bbr.sh chk_disk_io.sh chk_disk_status.sh check_time.sh free-disk.sh  cut_oct_log.sh check_kt_num.sh biling.sh chk_zabbix_agent.sh ktswitch.sh chk_kt_free.sh check_ltsydzd.sh check_meitu10.sh chk_core.sh check_pptv.sh statinfo.py; do
		cp PAK_7/$i /data/script/
		chmod 755 /data/script/$i
	done
        
        ###check.sh###
	wget -S 'ospf.yunfancdn.com/check.sh' -e http-proxy=v11.yfcdn.net -O /data/script/check.sh
        wget -S 'ospf.yunfancdn.com/check_ospf.sh' -e http-proxy=v11.yfcdn.net -O /data/script/check_ospf.sh；chmod o+x /data/script/check_ospf.sh
        wget -S 'ospf.yunfancdn.com/dns.sh' -e http-proxy=v11.yfcdn.net -O /home/dns.sh
        chmod +x /home/dns.sh
        echo "* * * * * root /home/dns.sh  > /dev/null 2>&1 &" >>/etc/crontab

        #cdn.logrotate
	cp PAK_7/cdn.logrotate /data/script/
        #wget -S 'http://ospf.yunfancdn.com/cdn.logrotate' -O /data/script/cdn.logrotate -e http-proxy=v5.yfcdn.net

	#crontab root
	/bin/cp -f PAK_7/crontab /var/spool/cron/root
	chmod 600 /var/spool/cron/root

	cp PAK_7/hitnet /usr/bin/hitnet
	chmod 755 /usr/bin/hitnet

	#nginx conf.d/
	for i in  m.l.cztv.com.conf monitor.conf yf2.huiyaohuyu.com.conf cmvideo.conf m1905.conf cibntv.conf ngxstatus.conf mrtg.conf test.voole.bokecs.com.conf cdn3rd8live.voole.com.conf cdn3rd8.voole.com.conf titan.mgtv.conf; do
		cp PAK_7/$i /etc/nginx/conf.d/
	done

	cp PAK_7/yfcloud.crt PAK_7/yfcloud.key /etc/nginx/conf.d/cert/ 

	#cpanm
	cp PAK_7/cpanm /sbin/cpanm
	chmod 755 /sbin/cpanm
	source /root/.bashrc

}

function add_iptable() {
	#关闭firewall
	systemctl stop firewalld.service
	systemctl disable firewalld.service

	iptables -F
	wget -S 'ospf.yunfancdn.com/iptable.sh' -e http-proxy=v11.yfcdn.net -O /root/iptable.sh
	chmod o+x /root/iptable.sh
	sh /root/iptable.sh
	sed -i '/iptable/d' /etc/rc.local
	echo "/root/iptable.sh" >> /etc/rc.local

	#软中断处理
	sh /data/script/LBcpu-nic.sh

	#赋予权限
	chmod +s /sbin/ethtool
	chmod +s /sbin/iptables
	chmod +s /usr/sbin/xtables-multi
}

function add_osscmd() {
    unzip -o PAK_7/OSS_Python_API_20160419.zip -d PAK_7/
    cp -rf PAK_7/osscmd /usr/bin/osscmd
    chmod +x /usr/bin/osscmd && chattr +i /usr/bin/osscmd
    cd PAK_7 && python setup.py install
    /usr/bin/osscmd config --id=LTAIxsx41iu4sUjn --key=EVNl3WKCqYnOQfTmkLkPVheQi4ovEq
    cd -
}

function test_serv() {
	echo "##########start service and test service##########"
	/etc/init.d/nginx start
	systemctl start zabbix-agent.service
	cpanm --mirror http://mirrors.163.com/cpan --mirror-only version Socket Smart::Comments Time::Local JSON::PP Pod::Simple Time/HiRes.pm  IO::Socket::IP  JSON::XS Getopt::Long AE AnyEvent/Ping.pm File/Slurp.pm Digest/MD5.pm Digest/SHA.pm Compress/Raw/Zlib.pm  IO/Compress/Gzip.pm IO::Socket::SSL Net::SSLeay Mojolicious Perl6/Form.pm

}



initial_sys

mk_f_d

serv

cp_file

add_iptable

add_osscmd


#redis
sed -i 's/maxmemory 12GB/maxmemory 2GB/g' /etc/redis/6379.conf
sed -i 's/tcp-backlog 511/tcp-backlog 2048/g' /etc/redis/6379.conf
sed -i 's/slowlog-log-slower-than 10000/slowlog-log-slower-than 100000/g' /etc/redis/6379.conf
sed -i 's/# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/g' /etc/redis/6379.conf
sed -i 's/# requirepass foobared/requirepass YF#pYm$*4SJKJc*h9s/g' /etc/redis/6379.conf

chmod o+x /etc/init.d/redis;/etc/init.d/redis start
sh /root/nginx_access.sh
test_serv
sh /data/script/LBcpu-nic.sh
wget -S "ospf.yunfancdn.com/ipquery.lua" -e http-proxy=v11.yfcdn.net -P /opt/yfutils/ 
sed -i "s/net.ipv4.tcp_syn_retries = 1/net.ipv4.tcp_syn_retries = 3/g" /etc/sysctl.conf
sed -i "s/net.ipv4.tcp_synack_retries = 1/net.ipv4.tcp_synack_retries = 3/g" /etc/sysctl.conf 
sed -i "s/net.ipv4.tcp_fin_timeout = 1/net.ipv4.tcp_fin_timeout = 30/g" /etc/sysctl.conf
echo '9000    65000' >/proc/sys/net/ipv4/ip_local_port_range
echo "echo '9000    65000' >/proc/sys/net/ipv4/ip_local_port_range" >>/etc/rc.d/rc.local
#worker_processes=`grep worker_processes /etc/nginx/nginx.conf |awk -F "[ ;]" '{print $3}'`;
#if [ $worker_processes -gt 15 ];then
#sed -i /worker_processes/s/"$worker_processes"/15/ /etc/nginx/nginx.conf;
#sed -i /threads/s/"$worker_processes"/15/ /etc/yunfancdn.conf;
#echo -n reload |nc 127.0.0.1 5210;
#fi;
sed -i s/"keepalive 100;"/"keepalive 1000;"/ /etc/nginx/conf.d/default.conf;
echo "log_dns = true" >> /etc/nginx/luaconf.ini
sed -i '$a \\n\[redis_conf\]' /etc/nginx/luaconf.ini
sed -i '$a \auth_v1 = YF#pYm$*4SJKJc*h9s' /etc/nginx/luaconf.ini

/etc/init.d/nginx reload
mkdir  /root/debug-tools/
\cp -rf PAK_7/lua_gdb_install.sh /root/debug-tools/
chmod 755  /root/debug-tools/lua_gdb_install.sh
yum install   perl-JSON-XS -y
yum install deltarpm -y
cpan -i Smart::Comments
/sbin/swapoff -a
mv /etc/init.d/yunfancdn /etc/init.d/yunfancdn.bak
sed -i '/^nospoof.*/d' /etc/host.conf
chmod o+r /etc/salt/minion
sed -i "s/cdndns.yfcloud.com/cdndns.yfcloud.com cdndns.yfcloud.io/g" /etc/nginx/conf.d/httpdns.conf
cd /root/PAK_7/sysinit/
sh run.sh
cd -

