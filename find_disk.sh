#!/bin/bash
disk=`lsblk -d | grep -v ^NAME | awk '{print $1}'`
first=1
echo -e "{\n"
echo -e "\t\"data\":[\n\n"

for i in `echo "$disk"`
do
    if [ $first -eq 0  ];then
        echo -e "\t,\n"
    fi
    first=0
    echo -e "\t{\n"
    echo -e "\t\t\"{#DEVICE}\":\"$i\"\n"
    echo -e "\t}\n"
done

echo -e "\n\t]\n"
echo -e "}\n"
