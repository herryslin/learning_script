#!/bin/bash

t1=`/usr/local/bin/ktremotemgr get -host 127.0.0.1 -port 1916 timestamp`

t2=`date +%s`

result=`perl -e "print abs($t2-$t1)"`

if [ $result -le 200  ];then
	echo 0
else
	echo $result
fi
