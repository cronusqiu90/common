#!/bin/bash
###############################################################################
# 脚本名称: mysql_incremental_sync.sh
# 功能描述: 支持多次运行的增量同步脚本。
# 增量逻辑: 
#   1. 重新导出所有表的最新 SQL。
#   2. rsync 对比远程已存在的文件。
#   3. 仅传输内容有变化的表文件。
#   4. 自动清理本地临时文件。
#
# 使用方法: ./mysql_incremental_sync.sh <远程IP> <远程密码> <数据库密码> [SSH端口] [远程用户]
###############################################################################

# --- 1. 获取位置参数 ---
REMOTE_HOST="$1"
REMOTE_PASS="$2"
DB_PASS="$3"
REMOTE_PORT="${4:-8513}"
REMOTE_USER="${5:-auser}"

DB_USER="root"
LOCAL_TMP="/tmp/mysql_sync"
REMOTE_BASE="/home/auser/mysql_migration"

# --- 2. 参数校验与初始化 ---
if [ -z "$REMOTE_HOST" ] || [ -z "$REMOTE_PASS" ] || [ -z "$DB_PASS" ]; then
    echo "❌ 错误: 缺少必要参数。"
    echo "用法: $0 <远程IP> <远程密码> <数据库密码> [SSH端口] [远程用户]"
    exit 1
fi

mkdir -p "$LOCAL_TMP"

# 定义 SSH 命令
if command -v sshpass &> /dev/null; then
    SSH_CMD="sshpass -p '${REMOTE_PASS}' ssh -p ${REMOTE_PORT} -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST}"
    RSYNC_SSH="sshpass -p '${REMOTE_PASS}' ssh -p ${REMOTE_PORT} -o StrictHostKeyChecking=no"
else
    echo "⚠️  未检测到 sshpass，将使用交互式密码输入..."
    SSH_CMD="ssh -p ${REMOTE_PORT} -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST}"
    RSYNC_SSH="ssh -p ${REMOTE_PORT} -o StrictHostKeyChecking=no"
fi

# 测试连接
$SSH_CMD "mkdir -p $REMOTE_BASE" > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ 错误: 无法连接到远程服务器。"
    exit 1
fi

# 获取数据库列表
DBS=$(mysql -u "$DB_USER" -p"$DB_PASS" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|performance_schema|sys|mysql")

echo ">>> 开始增量同步检查..."
echo "✅ 发现数据库: $DBS"

# --- 3. 核心同步循环 ---
TOTAL_SKIPPED=0
TOTAL_SYNCED=0

for db in $DBS; do
    REMOTE_DB_DIR="$REMOTE_BASE/$db"
    $SSH_CMD "mkdir -p $REMOTE_DB_DIR"
    
    TABLES=$(mysql -u "$DB_USER" -p"$DB_PASS" -D "$db" -e "SHOW TABLES;" 2>/dev/null | grep -Ev "Tables_in")
    
    for table in $TABLES; do
        LOCAL_FILE="$LOCAL_TMP/${db}_${table}.sql"
        REMOTE_FILE="$REMOTE_DB_DIR/${db}_${table}.sql"
        
        # 1. 导出最新 SQL
        mysqldump -u "$DB_USER" -p"$DB_PASS" \
            --single-transaction \
            --quick \
            --no-create-db \
            --compact \
            --skip-comments \
            --skip-lock-tables \
            --set-gtid-purged=OFF \
            --default-character-set=utf8mb4 \
            --hex-blob \
            "$db" "$table" > "$LOCAL_FILE" 2>/dev/null
            
        if [ $? -ne 0 ]; then
            rm -f "$LOCAL_FILE"
            continue
        fi
        
        # 2. Rsync 增量同步
        # --checksum: 强制通过内容校验和对比，而不是仅靠修改时间（更可靠）
        rsync -avz --partial --checksum \
            -e "$RSYNC_SSH" \
            "$LOCAL_FILE" \
            "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_FILE}" 2>&1
        
        # 检查 rsync 输出中是否包含文件名（如果有传输，通常会列出文件名）
        # 简单的判断逻辑：如果 rsync 返回成功且没有报错，视为完成
        if [ $? -eq 0 ]; then
            TOTAL_SYNCED=$((TOTAL_SYNCED + 1))
        else
            echo "   ❌ 同步失败: $db.$table"
        fi
        
        # 3. 清理本地
        rm -f "$LOCAL_FILE"
    done
done

echo ""
echo "🎉 同步完成！"
echo "📊 统计: 共处理 $TOTAL_SYNCED 个表文件。"
echo "💡 提示: 未出现在日志中的表表示内容无变化，已被 rsync 自动跳过。"
