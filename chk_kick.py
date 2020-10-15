#!/usr/bin/python
import json, urllib2

crawf='/tmp/kick.txt'

def get_kick():
    url = 'http://127.0.0.1:5211/statinfo'
    try:
        cont = urllib2.urlopen(url).read()
        decode = json.loads(cont)
        data = decode['store_info_ex']
        print 'disk check'
        for i in data:
            ot = i.split()[0]+'   '+i.split()[1]
            if ot.find('kicked') != -1:
                print ot
    except urllib2.URLError,e:
        print 'Can not connect 127.0.0.1:5211'
if __name__ == '__main__':
    get_kick()
