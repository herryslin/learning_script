#!/bin/bash

sed -i /default_type/a"\                      \'\$upstream_addr\t\$request_time\t\$upstream_response_time\t\$sent_http_oct_response_info\t\$body_start\t\$sent_http_x_bs_request_id\t\$http_origin_host\t\$http_x_cdn_reqid\t\$billing_kv\t\$upstream_http_content_length\t\$upstream_http_oct_orig_content_length\t\$yf_balancer\t\$lua_traceid\t\$sent_http_from\t\$http_p2p_only\t\$http_p2p_x_http_user_agent\t\$http_p2p_x_remote_addr\t\$http_p2p_x_http_referer\t\$http_p2p_x_forwarded_for\t\$http_p2p_x_request_time\t\$http_p2p_x_response_time\t\$http_p2p_x_request_body_length\t\$http_ybdj_code\t\$http_ybdj_forbidden\t\$http_ybdj_speedlimit\'\;" /etc/nginx/nginx.conf

 sed -i /default_type/a"\                      \'\$bytes_sent\t\$fake_body_bytes_sent\t\$http_range\t\$sent_http_content_length\t$sent_http_content_encoding\$connection\t\$connection_requests\t'" /etc/nginx/nginx.conf

 sed -i /default_type/a"\                      \'\"\$http_user_agent\"\t\$http_x_forwarded_for\t\$http_x_real_ip\t'" /etc/nginx/nginx.conf


 sed -i /default_type/a"\                      \'\$status\t\$body_bytes_sent\t\$http_referer\t'" /etc/nginx/nginx.conf

 sed -i /default_type/a"\    log_format\  main\  \'\$remote_addr\t\$server_addr\t\$hostname\t\[\$time_local\]\t\$request_method\t\$scheme\:\/\/\$http_host\$uri\?\$query_string\t'" /etc/nginx/nginx.conf

