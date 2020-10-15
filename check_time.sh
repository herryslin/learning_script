#!/bin/bash

/usr/sbin/ntpdate -u timeserver.yfcdn.net >>  /var/log/ntpdate.log || /usr/sbin/ntpdate -u time.nist.gov >>  /var/log/ntpdate.log

if [ $? -ne 0 ];then
    rdate -s time.nist.gov  && echo "0" > /tmp/check_time.log  ||  echo "1" > /tmp/check_time.log
fi
hwclock -w >/dev/null 2>&1
