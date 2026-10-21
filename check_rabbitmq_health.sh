#!/bin/bash

RABBITMQ_HOST="localhost"
USER="admin"
PASS="${1:-guest}"

echo "========================================="
echo "RabbitMQ 核心指标快照"
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================="

# 1. 连接数
if command -v rabbitmqctl &> /dev/null; then
    CONN_COUNT=$(rabbitmqctl list_connections name --quiet | wc -l)
else
    CONN_COUNT=$(curl -s -u ${USER}:${PASS} http://${RABBITMQ_HOST}:15672/api/connections | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
fi
echo "当前连接数: $CONN_COUNT"

# 2. 总消息堆积数
if command -v rabbitmqctl &> /dev/null; then
    TOTAL_MSG=$(rabbitmqctl list_queues messages --quiet | awk '{sum+=$1} END {print sum+0}')
else
    TOTAL_MSG=$(curl -s -u ${USER}:${PASS} http://${RABBITMQ_HOST}:15672/api/queues | python3 -c "import sys,json; print(sum(q.get('messages',0) for q in json.load(sys.stdin)))" 2>/dev/null || echo "0")
fi
echo "总消息堆积: $TOTAL_MSG"

# 3. 内存使用 (MB)
if command -v rabbitmqctl &> /dev/null; then
    MEM_USED=$(rabbitmqctl status | grep "memory" | grep "total" | awk '{printf "%.2f", $2/1024/1024}')
    MEM_LIMIT=$(rabbitmqctl status | grep "mem_limit" | awk '{printf "%.2f", $2/1024/1024}')
    if [ -n "$MEM_LIMIT" ] && [ "$MEM_LIMIT" != "0.00" ]; then
        MEM_PCT=$(awk "BEGIN {printf \"%.1f\", $MEM_USED/$MEM_LIMIT*100}")
    else
        MEM_PCT="N/A"
    fi
    echo "内存使用: ${MEM_USED} MB / ${MEM_LIMIT} MB (${MEM_PCT}%)"
else
    curl -s -u ${USER}:${PASS} http://${RABBITMQ_HOST}:15672/api/nodes | \
    python3 -c "
import sys, json
nodes = json.load(sys.stdin)
for n in nodes:
    used = n.get('mem_used',0)/1024/1024
    limit = n.get('mem_limit',0)/1024/1024
    pct = (used/limit*100) if limit > 0 else 0
    print(f'内存使用: {used:.2f} MB / {limit:.2f} MB ({pct:.1f}%)')
" 2>/dev/null
fi

# 4. 磁盘剩余 (MB)
if command -v rabbitmqctl &> /dev/null; then
    DISK_FREE=$(rabbitmqctl status | grep "disk_free" | head -1 | awk '{printf "%.2f", $2/1024/1024}')
    DISK_LIMIT=$(rabbitmqctl status | grep "disk_free_limit" | awk '{printf "%.2f", $2/1024/1024}')
    echo "磁盘剩余: ${DISK_FREE} MB (限制: ${DISK_LIMIT} MB)"
else
    curl -s -u ${USER}:${PASS} http://${RABBITMQ_HOST}:15672/api/nodes | \
    python3 -c "
import sys, json
nodes = json.load(sys.stdin)
for n in nodes:
    free = n.get('disk_free',0)/1024/1024
    limit = n.get('disk_free_limit',0)/1024/1024
    print(f'磁盘剩余: {free:.2f} MB (限制: {limit:.2f} MB)')
" 2>/dev/null
fi

echo "========================================="
