#! /bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 {add|remove|list} <port>"
    exit 1
fi

ACTION="$1"
PORT="$2"
if [ "$ACTION" = "add" ]; then
    firewall-cmd --add-port=${PORT} --permanent
    firewall-cmd --reload
    firewall-cmd --list-ports
fi
if [ "$ACTION" = "remove" ]; then
    firewall-cmd --remove-port=${PORT} --permanent
    firewall-cmd --reload
    firewall-cmd --list-ports
fi
if [ "$ACTION" = "remove" ]; then
    firewall-cmd --list-ports
fi
