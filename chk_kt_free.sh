#!/bin/bash
shijian=`date +%F|cut -c 1-9`
sed -i '/'$shijian'/!d' /data/kyoto/ktserver-log
