#!/bin/bash
###############################################################################
# 脚本名称: mysql_migrate.sh
# 功能描述: 将源端 MySQL (5.5) 数据逐表导出为干净 SQL，并通过 rsync 同步至远程服务器。
# 使用方法: ./mysql_migrate.sh <远程IP> <远程密码> <数据库密码> [SSH端口] [远程用户]
#
# 参数说明 (按顺序):
#   $1 : 远程服务器 IP 地址 (必填)
#   $2 : 远程服务器用户密码 (必填)
#   $3 : 源端数据库 root 密码 (必填)
#   $4 : 远程 SSH 端口 (选填，默认 8513)
#   $5 : 远程服务器用户名 (选填，默认 auser)
#
# 依赖工具: mysqldump, rsync, ssh, sshpass
# 注意事项: 
#   1. 请确保 /tmp 目录有足够空间存放【单张最大表】的 SQL 文件。
#   2. 建议安装 sshpass (yum install -y sshpass) 以实现完全自动化。
###############################################################################

# --- 1. 获取位置参数 ---
REMOTE_HOST="$1"
REMOTE_PASS="$2"
DB_PASS="$3"
REMOTE_PORT="${4:-8513}"       # 如果第4个参数为空，则默认为 8513
REMOTE_USER="${5:-auser}"      # 如果第5个参数为空，则默认为 auser

DB_USER="root"
LOCAL_TMP="/tmp/mysql_sync"
REMOTE_BASE="/home/auser/mysql_migration"

# --- 2. 参数校验 ---
if [ -z "$REMOTE_HOST" ] || [ -z "$REMOTE_PASS" ] || [ -z "$DB_PASS" ]; then
    echo "❌ 错误: 缺少必要参数。"
    echo ""
    echo "用法: $0 <远程IP> <远程密码> <数据库密码> [SSH端口] [远程用户]"
    echo ""
    echo "示例: $0 183.87.144.18 'MyRemotePass' 'MyDbPass' 8513 auser"
    exit 1
fi

echo ">>> 正在初始化环境..."
mkdir -p "$LOCAL_TMP"

# 定义 SSH 连接命令
if command -v sshpass &> /dev/null; then
    SSH_CMD="sshpass -p '${REMOTE_PASS}' ssh -p ${REMOTE_PORT} -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST}"
    RSYNC_SSH="sshpass -p '${REMOTE_PASS}' ssh -p ${REMOTE_PORT} -o StrictHostKeyChecking=no"
else
    echo "⚠️  未检测到 sshpass，将在每次连接时要求手动输入远程密码..."
    SSH_CMD="ssh -p ${REMOTE_PORT} -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST}"
    RSYNC_SSH="ssh -p ${REMOTE_PORT} -o StrictHostKeyChecking=no"
fi

# 测试连接并创建远程目录
echo ">>> 测试远程连接 [$REMOTE_HOST:${REMOTE_PORT}]..."
$SSH_CMD "mkdir -p $REMOTE_BASE"
if [ $? -ne 0 ]; then
    echo "❌ 错误: 无法连接到远程服务器，请检查 IP、端口或密码。"
    exit 1
fi

# 获取所有业务数据库列表
DBS=$(mysql -u "$DB_USER" -p"$DB_PASS" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|performance_schema|sys|mysql")

if [ -z "$DBS" ]; then
    echo "❌ 错误: 未获取到任何数据库列表，请检查数据库账号权限。"
    exit 1
fi

echo "✅ 发现以下数据库: $DBS"

# --- 3. 核心同步循环 ---
for db in $DBS; do
    echo ""
    echo "========================================================"
    echo ">>> 正在处理数据库: [$db]"
    echo "========================================================"
    
    REMOTE_DB_DIR="$REMOTE_BASE/$db"
    
    # 确保远程数据库目录存在
    $SSH_CMD "mkdir -p $REMOTE_DB_DIR"
    
    # 获取当前库下的所有表
    TABLES=$(mysql -u "$DB_USER" -p"$DB_PASS" -D "$db" -e "SHOW TABLES;" 2>/dev/null | grep -Ev "Tables_in")
    
    if [ -z "$TABLES" ]; then
        echo "   ⚠️  数据库 [$db] 为空，跳过。"
        continue
    fi
    
    for table in $TABLES; do
        LOCAL_FILE="$LOCAL_TMP/${db}_${table}.sql"
        REMOTE_FILE="$REMOTE_DB_DIR/${db}_${table}.sql"
        
        echo "   -> 正在导出并同步表: [$table]"
        
        # 1. 导出干净 SQL 文件
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
            echo "   ❌ 导出失败: $table"
            rm -f "$LOCAL_FILE"
            continue
        fi
        
        # 2. Rsync 增量同步到远程
        rsync -avz --partial \
            -e "$RSYNC_SSH" \
            "$LOCAL_FILE" \
            "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_FILE}"
            
        if [ $? -eq 0 ]; then
            echo "   ✅ 同步成功: $table"
        else
            echo "   ❌ 同步失败: $table"
        fi
        
        # 3. 立即清理本地临时文件
        rm -f "$LOCAL_FILE"
    done
done

echo ""
echo "🎉 所有数据库同步任务已完成！"
