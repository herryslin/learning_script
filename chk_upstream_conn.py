#!/usr/bin/python
import json, urllib2

crawf='/tmp/.oct_upstream_conn.txt'

def get_conn():
    g = file(crawf, 'w+')
    url = 'http://127.0.0.1:5211/statinfo'
    cont = urllib2.urlopen(url).read()
    g.write(cont)
    g.close()

    f = file(crawf, 'r')
    sdata = f.read()
    decode = json.loads(sdata)
    data = decode['connection_out']
    print data
if __name__ == '__main__':
    get_conn()
