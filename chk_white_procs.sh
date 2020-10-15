#!/bin/bash
PATH=/bin:/sbin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin
export PATH

white_list='/tmp/white_procs.list'
white_list1='/tmp/white_procs.list1'
whilte_list_update='true'
procs_check_log='/tmp/white_procs_check.log'

test -f /bin/yf.ps || (cp /bin/ps /bin/yf.ps && chmod +x /bin/yf.ps)
(test -f /sbin/lsof && test -f /usr/sbin/lsof)|| yum -y install lsof &> /dev/null
test -f /usr/sbin/yf.lsof  || (cp /usr/sbin/lsof /usr/sbin/yf.lsof && chmod +x /usr/sbin/yf.lsof) &> /dev/null
test -f $white_list || wget -O $white_list "http://ospf.yunfancdn.com/white_procs.list" -e http-proxy=v5.yfcdn.net &> /dev/null

if [ $whilte_list_update == 'true' -o "$(date +%H%M)" == "1400" -o "$(date +%H%M)" == "1800" ];then  #每个更新两次进程白名单
    wget -O $white_list "http://ospf.yunfancdn.com/white_procs.list" -e http-proxy=v5.yfcdn.net &> /dev/null
fi

grep -vE "^#|^$" $white_list > $white_list1
pidname_patten=$(cat $white_list1 | tr "\n" "|" | sed 's/|$//'|sed 's/ /./g'|sed 's/-/./g')
netpid_count=$(yf.lsof -i -nP | tr -s [:space:] | cut -d " " -f 2|tail -n +2 | sort | uniq | xargs yf.ps -fp | tr -s [:space:] | cut -d " " -f 9- | sed '1d'| grep -vE "$pidname_patten"| tee /tmp/pidname.tmp | wc -l)

if [ "$netpid_count" -ge 1 ];then #正常返回数字0，异常则返回异常进程数
    echo `date` >> $procs_check_log
    pidname_p=$(cat /tmp/pidname.tmp| tr "\n" "|" | sed 's/|$//'|sed 's/ /./g'|sed 's/-/./g')
    yf.ps aux | grep -E "$pidname_p"| grep -v grep &>> $procs_check_log
    echo $netpid_count
else
    echo 0
fi
