#!/bin/bash

mem_avail_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
swap_free_kb=$(awk '/^SwapFree:/ {print $2}' /proc/meminfo)
total_available_kb=$((mem_avail_kb + swap_free_kb))
total_available_mb=$(awk "BEGIN {printf \"%.2f\", $total_available_kb / 1024}")

disk_avail_gb=`df -h / |grep -v Filesystem |awk '{print$4}'`
echo ${total_available_mb},${disk_avail_gb}
