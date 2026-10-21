#!/bin/bash

# RabbitMQ 健康检查脚本
# 需要安装: rabbitmqctl 或启用 management plugin

RABBITMQ_HOST="${1:-localhost}"
RABBITMQ_PORT="${2:-15672}"
USER="${3:-admin}"
PASS="${4:-guest}"

echo "========================================="
echo "RabbitMQ 服务器状态检查"
echo "主机: $RABBITMQ_HOST"
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================="

# 方法1: 使用 rabbitmqctl (本地执行)
if command -v rabbitmqctl &> /dev/null; then
    echo ""
    echo "【连接数统计】"
    rabbitmqctl list_connections name peer_host peer_port state | head -20
    CONN_COUNT=$(rabbitmqctl list_connections name --quiet | wc -l)
    echo "总连接数: $CONN_COUNT"
    
    echo ""
    echo "【队列消息堆积】"
    rabbitmqctl list_queues name messages messages_ready messages_unacknowledged memory | sort -k2 -nr | head -20
    
    TOTAL_MESSAGES=$(rabbitmqctl list_queues messages --quiet | awk '{sum+=$1} END {print sum}')
    echo "总消息数: $TOTAL_MESSAGES"
    
    echo ""
    echo "【系统资源】"
    rabbitmqctl status | grep -A 5 "disk_free_limit\|mem_limit\|mem_used"
    
else
    # 方法2: 使用 HTTP API (远程执行)
    BASE_URL="http://${RABBITMQ_HOST}:${RABBITMQ_PORT}/api"
    
    echo ""
    echo "【连接数统计】"
    CONN_DATA=$(curl -s -u ${USER}:${PASS} ${BASE_URL}/connections)
    CONN_COUNT=$(echo $CONN_DATA | python3 -c "import sys,json; data=json.load(sys.stdin); print(len(data))" 2>/dev/null || echo "解析失败")
    echo "总连接数: $CONN_COUNT"
    
    echo ""
    echo "【队列消息堆积 TOP 20】"
    curl -s -u ${USER}:${PASS} ${BASE_URL}/queues | \
    python3 -c "
import sys, json
data = json.load(sys.stdin)
sorted_q = sorted(data, key=lambda x: x.get('messages', 0), reverse=True)[:20]
print(f'{\"队列名\":<40} {\"总消息\":<10} {\"待消费\":<10} {\"未确认\":<10}')
for q in sorted_q:
    name = q['name'][:38]
    msgs = q.get('messages', 0)
    ready = q.get('messages_ready', 0)
    unack = q.get('messages_unacknowledged', 0)
    print(f'{name:<40} {msgs:<10} {ready:<10} {unack:<10}')
" 2>/dev/null
    
    TOTAL_MESSAGES=$(curl -s -u ${USER}:${PASS} ${BASE_URL}/queues | \
    python3 -c "import sys,json; data=json.load(sys.stdin); print(sum(q.get('messages',0) for q in data))" 2>/dev/null || echo "N/A")
    echo "总消息数: $TOTAL_MESSAGES"
    
    echo ""
    echo "【系统资源】"
    curl -s -u ${USER}:${PASS} ${BASE_URL}/nodes | \
    python3 -c "
import sys, json
data = json.load(sys.stdin)
for node in data:
    name = node['name']
    mem_used = node.get('mem_used', 0) / 1024 / 1024
    mem_limit = node.get('mem_limit', 0) / 1024 / 1024
    disk_free = node.get('disk_free', 0) / 1024 / 1024 / 1024
    disk_limit = node.get('disk_free_limit', 0) / 1024 / 1024 / 1024
    fd_used = node.get('fd_used', 0)
    fd_total = node.get('fd_total', 0)
    print(f'节点: {name}')
    print(f'  内存: {mem_used:.2f} MB / {mem_limit:.2f} MB ({mem_used/mem_limit*100:.1f}%)')
    print(f'  磁盘: {disk_free:.2f} GB 可用 / {disk_limit:.2f} GB 限制')
    print(f'  文件描述符: {fd_used} / {fd_total}')
" 2>/dev/null
fi

echo ""
echo "========================================="
echo "检查完成"
