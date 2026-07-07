#!/bin/bash

LIMIT=50

do_limit() {
        pid=$1
        pgrep -f "cpulimit -p $pid" > /dev/null && return
        renice -n 10 -p $pid >/dev/null 2>&1
        cpulimit -p "$pid" -l $LIMIT >/dev/null 2>&1 &
}

pid=`cat /var/run/mysqld/mysqld.pid`
[ -n "$pid" ] && do_limit "$pid"
