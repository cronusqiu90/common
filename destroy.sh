#! /bin/bash

systemctl stop supervisord
systemctl stop mysql
systemctl stop telegraf

pkill -9 "python"
pkill -9 "TC"
pkill -9 "cj"
pkill -9 "Crawler"
pkill -9 "TRClient"
ps -ef |grep ^telegraf|awk '{print$2}'|xargs kill -9
ps -ef |grep ^auser|awk '{print$2}'|xargs kill -9

rm -rf /usr/bin/v2ray
rm -rf /etc/v2ray/config.json
rm -rf /etc/telegraf
rm -rf /usr/local/bin/*
rm -rf /home/auser
rm -rf /usr/local/miniconda3
rm -rf /opt/*
rm -rf /var/lib/mysql
rm -rf /root/.ssh
rm -rf /root/*
rm -rf /root/.cache
rm -rf /root/.conda
rm -rf /root/.config
rm -rf /root/.local
