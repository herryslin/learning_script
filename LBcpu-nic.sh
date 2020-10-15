#!/bin/bash

# setting up irq affinity according to /proc/interrupts
# 2008-11-25 Robert Olsson
# 2009-02-19 updated by Jesse Brandeburg
#
# > Dave Miller:
# (To get consistent naming in /proc/interrups)
# I would suggest that people use something like:
#       char buf[IFNAMSIZ+6];
#
#       sprintf(buf, "%s-%s-%d",
#               netdev->name,
#               (RX_INTERRUPT ? "rx" : "tx"),
#               queue->index);
#
#  Assuming a device with two RX and TX queues.
#  This script will assign:
#
#       eth0-rx-0  CPU0
#       eth0-rx-1  CPU1
#       eth0-tx-0  CPU0
#       eth0-tx-1  CPU1
#

set_affinity()
{
    MASK=$((1<<$VEC))
    printf "[%s]\t%s VEC=%d mask=%X for /proc/irq/%d/smp_affinity RawData=%s\n" "`date "+%F %T"`" \
	$DIR \
	$VEC \
	$MASK \
	$IRQ \
	`cat /proc/irq/$IRQ/smp_affinity` >> $log;
    printf "%X" $MASK > /proc/irq/$IRQ/smp_affinity
    #echo $DEV mask=$MASK for /proc/irq/$IRQ/smp_affinity
    #echo $MASK > /proc/irq/$IRQ/smp_affinity
}

#if [ "$1" = "" ] ; then
#        echo "Description:"
#        echo "    This script attempts to bind each queue of a multi-queue NIC"
#        echo "    to the same numbered core, ie tx0|rx0 --> cpu0, tx1|rx1 --> cpu1"
#        echo "usage:"
#        echo "    $0 eth0 [eth1 eth2 eth3]"
#fi


# check for irqbalance running
IRQBALANCE_ON=`ps ax | grep -v grep | grep -q irqbalance; echo $?`
if [ "$IRQBALANCE_ON" == "0" ] ; then
        echo " WARNING: irqbalance is running and will"
        echo "          likely override this script's affinitization."
        echo "          Please stop the irqbalance service and/or execute"
        echo "          'killall irqbalance'"
		service irqbalance stop
fi

#
# Set up the desired devices.
#
log="/var/log/lbcpu-nic.log";
CPU=$((`cat /proc/cpuinfo |grep processor|wc -l`));
VEC=$(($CPU - 1));
RX_NUM=$((2 ** $CPU - 1))


for DEV in `/sbin/ip addr | grep ^[0-9] | egrep -v 'DOWN|lo' | awk '{print $2}' | tr -d :`
do
	SU_RPS=`ls /sys/class/net/${DEV}/queues/ >/dev/null ;echo $?` #�ں��Ƿ�֧��RPS
	if [ "$SU_RPS" == "0" ];then
  #GET NIC-Queue-Number
		for IRQ in `cat /proc/interrupts |grep ${DEV}| cut  -d:  -f1| sed "s/ //g"`;
		do
			DIR=`cat /proc/interrupts | egrep -i -e "^$IRQ|^\s+$IRQ"| awk '{print $NF}'`; # Get IRQ corresponding DIR name.
			if [ -n  "$IRQ" ]; then
				set_affinity;
				VEC=$(($VEC - 1));
				if [ "$VEC" -lt 0 ]; then
					VEC=$(($CPU - 1));
				fi
			else
				echo -e "["`date "+%F %T"`"]\tget $DIR IRQ Failed." >> $log;
			fi
		done

		#set the rps rfs.  

		for RX_DIR in `find   /sys/class/net/${DEV}/queues/* -name rx-*`
		do
			printf "%X" $RX_NUM > $RX_DIR/rps_cpus
			echo 4096 >$RX_DIR/rps_flow_cnt
			printf "[%s]\t CPU=%d RX_NUM=%X for %s RawData=%s\n" "`date "+%F %T"`" \
			$CPU \
			$RX_NUM \
			$RX_DIR/rps_cpus \
			`cat $RX_DIR/rps_cpus` >> $log 
		done
		echo 32768 > /proc/sys/net/core/rps_sock_flow_entries  
		echo -e "["`date "+%F %T"`"]\tset 32768 for /proc/sys/net/core/rps_sock_flow_entries ">> $log
	else
		echo -e "["`date "+%F %T"`"]\tNot Support RPS."
	fi
done
echo -e "["`date "+%F %T"`"]\tSet down over." >> $log;
