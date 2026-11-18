#! /bin/bash

systemctl stop supervisord
systemctl stop mysql


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
