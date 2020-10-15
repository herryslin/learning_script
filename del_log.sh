#!/bin/bash
ngx_access="/data/log/nginx/backup/"
oct_access="/data/log/octopus/"
json_bak="/data/log/temp/"
oct_billing='/data/log/octopus/billing/'
ngx_billing='/data/log/nginx/billing/'
ngx_core='/data/ngx_core/'

#删除10天前的nginx access.log
find $ngx_access -mtime +7 -exec rm -f {} \;
#删除10天前的oct access.log
find $oct_access -mtime +7 -exec rm -f {} \;
#删除10天前的nginx json log
find $json_bak -mtime +7 -exec rm -f {} \;
#删除7天前的oct billing.log
find $oct_billing -mtime +7 -exec rm -f {} \;
#删除7天前的nginx billing.log
find $ngx_billing -mtime +7 -exec rm -f {} \;
#删除2天前的nginx core
find $ngx_core -mtime +2 -exec rm -f {} \;
