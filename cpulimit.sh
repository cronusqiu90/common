#!/bin/bash

LIMIT=70

start_limit() {
    pid=$1
    pgrep -f "cpulimit -p $pid" > /dev/null && return
    renice -n 10 -p $pid >/dev/null 2>&1
    cpulimit -p "$pid" -l $LIMIT >/dev/null 2>&1 &
}

for app in TC6.py MQ6.py; do
    pid=$(pgrep -f "$app" | head -n 1)
    [ -n "$pid" ] && start_limit "$pid"
done
supervisorctl status | awk '/RUNNING/ {print $4}' | grep -oE '[0-9]+' | while read pid; do
    [ -n "$pid" ] && start_limit "$pid"
done
