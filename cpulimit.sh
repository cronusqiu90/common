#!/bin/bash

LIMIT=70
pkill -f "cpulimit" 2>/dev/null
sleep 1

supervisorctl status | grep -E "RUNNING" | while read -r line; do
    program=$(echo "$line" | awk '{print $1}')
    pid=$(echo "$line" | grep -oE 'pid [0-9]+' | awk '{print $2}')
    if [ -n "$pid" ] && [ "$pid" -gt 0 ]; then
        if kill -0 $pid 2>/dev/null; then
            renice -n 10 -p $pid >/dev/null 2>&1
            nohup cpulimit -p $pid -l $LIMIT -z >/dev/null 2>&1 &
        fi
    fi
done
