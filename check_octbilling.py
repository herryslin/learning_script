#!/usr/bin/python
import commands
import json
import urllib2
import socket
from datetime import datetime
import time

def data_request(IP):
    try:
        curl_data = urllib2.urlopen('http://%s:5211/statinfo' % IP,timeout=5).read()
        curl_data=json.loads(curl_data)
        bing_date=(datetime.now() - datetime.strptime(time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(float(curl_data['last_report_billing']))), '%Y-%m-%d %H:%M:%S')).seconds
        if curl_data['speed_out'] > 100 and bing_date > 600:
            print 1
        else:
            print 0
    except Exception,e:
        pass
if __name__ == "__main__":
    data_request('127.0.0.1')


