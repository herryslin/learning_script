#!/usr/bin/python
import commands
import json
import urllib2
import socket

data = open('/root/buf_rs.txt','w')

def data_request(IP,HOSTNAME):
    sys={}
    sys['ip']  = IP
    sys['hostname'] = HOSTNAME
    sys['node'] = HOSTNAME[:7]
    buf_rs_count=0
    buf_rbs_count=0
    buf_rs_sum=0
    buf_rbs_sum=0
    try:
        curl_data = urllib2.urlopen('http://%s:5211/statinfo' % IP,timeout=5).read()
        for i in json.loads(curl_data)['store_io_stat'][1:]:
            i_split=i.split()
            buf_rs_count = buf_rs_count + int(i_split[13]) - int(i_split[1])
            buf_rbs_count = buf_rbs_count + int(i_split[14]) - int(i_split[2])
            buf_rs_sum = buf_rs_sum + int(i_split[13])
            buf_rbs_sum = buf_rbs_sum + int(i_split[14])
        sys['buf_rs_count'] = buf_rs_count
        sys['buf_rs_sum'] = buf_rs_sum
        sys['buf_rbs_count'] = buf_rbs_count 
        sys['buf_rbs_sum'] = buf_rbs_sum
        data_dumps = json.dumps(sys)
        data.write('%s\n' % data_dumps)
    except:
        sys['buf_rs_count'] = buf_rs_count
        sys['buf_rs_sum'] = buf_rs_sum
        sys['buf_rbs_count'] = buf_rbs_count
        sys['buf_rbs_sum'] = buf_rbs_sum
        data_dumps = json.dumps(sys)
        data.write('%s\n' % data_dumps)

if __name__ == "__main__":
    ip = commands.getstatusoutput("/sbin/ip a|grep global|grep -v 127.0.0.1|grep -v '/32'|awk '{print $2}'|/usr/bin/awk -F '/' '{print $1}'|grep -v '^10\.'|head -1")[1]
    data_request(ip, socket.gethostname())
    data.close()
    file_md5 = commands.getstatusoutput("md5sum /root/buf_rs.txt|awk '{print $1}'")[1]
    file_put = commands.getstatusoutput("/usr/bin/osscmd put /root/buf_rs.txt oss://ngx-log/statinfo/`uname -n` --headers='Content-MD5:%s' --check_md5=true" % file_md5)
