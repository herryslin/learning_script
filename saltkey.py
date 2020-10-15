#!/usr/bin/python
import os
import socket
import requests
import json


url = 'http://yunweipt.yfcdn.net:9091/api/assets/saltstack/keymanage/'

hostname = socket.gethostname()
try:
    superstratum = os.popen('cat /etc/salt/minion | grep "^master:"').read().split(':')[1].split('\n')[0]
except:
    superstratum = ''

try:
    zabbixsuperstratum = os.popen('cat /etc/zabbix/zabbix_agentd.conf | grep "^Server="').read().split('=')[1].split('\n')[0]
except:
    zabbixsuperstratum = ''


def post_data(hostname,superstratum,label):
    ret = ''
    body = {"hostname":hostname,"superstratum":superstratum,"label":label}
    headers = {'content-type': "application/json", 'Authorization': 'Token 2c2fa68d045e6167d5434ddb693a90d4781b3886'}
    response = requests.post(url, data = json.dumps(body), headers = headers, timeout=5)
    if response.status_code == 200:
        data = json.loads(response.text)
        if data['code'] == 200:
            ret = data['data']['data']
        else:
            ret = 1
    else:
        ret = 1
    return ret

if superstratum:
    ret = post_data(hostname,superstratum,'vod')
    print(ret)
else:
    print(1)

