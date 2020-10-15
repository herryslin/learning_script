#!/usr/bin/python
import json, urllib2, sys

para = sys.argv[1]

def get_info(par):
    url = 'http://127.0.0.1:5211/statinfo'
    try:
        cont = urllib2.urlopen(url).read()
        decode = json.loads(cont)
        data = decode[par]
        print data
    except urllib2.URLError,e:
        print 'Can not connect 127.0.0.1:5211'
if __name__ == '__main__':
    get_info(para)
