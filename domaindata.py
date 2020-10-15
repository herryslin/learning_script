#!/usr/bin/python
#coding:utf-8
import os,json
import sys,subprocess

argvdatadomain = sys.argv[1]
argvdatakey =  sys.argv[2]
try:
    argvdatakey1 =  sys.argv[3]
except:
    pass

cmd="/usr/bin/curl -s 'http://monitor.yfcdn.net/edgestatus' -H 'Yf-Status-Domain:{}' -x 127.0.0.1:80".format(argvdatadomain)

data =  subprocess.check_output(cmd,shell=True)
data = json.loads(data)
if isinstance(data[argvdatadomain][argvdatakey],dict):
    try:
        print(data[argvdatadomain][argvdatakey][argvdatakey1])
    except:
        print(0)
else:
    try:
        print(data[argvdatadomain][argvdatakey])
    except:
        print(0)
