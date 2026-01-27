#! /bin/bash


systemctl stop aliyun.service
systemctl disable aliyun.service
rm -rf /etc/systemd/system/aliyun.service
rm -rf /usr/local/share/aliyun-assist 

systemctl stop AssistDaemon.service
systemctl disable AssistDaemon.service
rm -rf /etc/systemd/system/AssistDaemon.service
rm -rf /usr/local/share/assist-daemon


systemctl stop cloudResetPwdUpdateAgent
systemctl disable cloudResetPwdUpdateAgent

sudo systemctl daemon-reload

