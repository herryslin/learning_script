#!/bin/bash
#block device info for oct store
#author by zrw 20160930

case "$2" in
    free)
        echo -n status | nc 127.0.0.1 5210 | grep $1 | awk '{print $5}'
        ;;
    used)
        echo -n status | nc 127.0.0.1 5210 | grep $1 | awk '{print $4}'
        ;;
    total)
        echo -n status | nc 127.0.0.1 5210 | grep $1 | awk '{print $3}'
        ;;
esac

