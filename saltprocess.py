#!/usr/bin/python
import os

data = list(set(map(lambda x:x.split(':')[0],os.popen("ps aux | grep salt-minion | grep -v grep  | awk '{print $9}' ").read().split('\n')[:-1])))
if len(data) == 1:
    print(0)
else:
    print(1)

