#!/usr/bin/python
#coding:utf-8

import sys
import json,os

os.popen("curl -so /tmp/domain.txt ospf.yunfancdn.com/domain.txt 2>&1 > /dev/null")

#os.popen("echo {} >>/tmp/a1".format(data))

argvdata = sys.argv[1:]
ports = []
a = os.popen("echo {} >>/tmp/a1".format(argvdata))
with open("/tmp/domain.txt") as file:
    data = file.read()
for i in json.loads(data)['domain']:
    ports += [{'{#DOMAINDATA}':i.strip()}]

print json.dumps({'data':ports},sort_keys=True,indent=4,separators=(',',':'))
