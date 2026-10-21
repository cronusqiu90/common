#! /bin/bash

function drop_service(){
    name=$1
    servicePath=$(systemctl show $name -p FragmentPath | cut -d= -f2-)
    systemctl stop $name
    systemctl disable $name
    rm -rf servicePath
}
drop_service aliyun
drop_service AssistDaemon
drop_service cloudResetPwdUpdateAgent
sudo systemctl daemon-reload

rm -rf /usr/local/share/aliyun-assist 
rm -rf /usr/local/share/assist-daemon
