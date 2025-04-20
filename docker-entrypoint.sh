#!/bin/sh
# 8080でhttpd（busybox）をバックグラウンド起動
busybox httpd -f -p 8080 &

exec ./frps -c frps.toml
