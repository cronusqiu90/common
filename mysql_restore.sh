#!/bin/bash
###############################################################################
# 脚本名称: mysql_restore.sh
# 功能描述: 在目标服务器本地执行，从固定目录自动扫描并恢复 MySQL 数据。
# 使用方法: ./mysql_restore.sh <数据库密码>
#
# 参数说明:
#   $1 : MySQL root 密码 (必填)
#
# 固定配置:
#   BACKUP_DIR: /home/auser/mysql_migration (不可更改)
#
# 注意事项:
#   1. 确保目标端已安装 MySQL 8.0。
#   2. 脚本会自动处理 utf8mb4 字符集。
#   3. 导入过程中会临时优化 MySQL 参数以加速，结束后自动恢复。
###############################################################################

# --- 1. 获取位置参数 ---
MYSQL_PASS="$1"

# --- 2. 固定配置与校验 ---
BACKUP_DIR="/home/auser/mysql_migration"

if [ -z "$MYSQL_PASS" ]; then
    echo "❌ 错误: 缺少数据库密码参数。"
    echo ""
    echo "用法: $0 <数据库密码>"
    echo ""
    echo "示例: $0 'MyDbPass123'"
    exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ 错误: 固定备份目录 [$BACKUP_DIR] 不存在。"
    echo "请确认同步脚本是否已成功执行。"
    exit 1
fi

echo ">>> 正在从固定目录 [$BACKUP_DIR] 恢复数据..."

# --- 3. 优化 MySQL 导入环境 ---
echo ">>> 正在优化导入环境 (加速模式)..."
mysql -u root -p"$MYSQL_PASS" -e "
SET GLOBAL innodb_flush_log_at_trx_commit = 2;
SET GLOBAL sync_binlog = 0;
SET GLOBAL unique_checks = 0;
SET GLOBAL foreign_key_checks = 0;
SET SESSION sql_mode = 'NO_ENGINE_SUBSTITUTION';
" 2>/dev/null

if [ $? -ne 0 ]; then
    echo "⚠️  警告: 无法设置全局优化参数，将以默认配置导入。"
fi

# --- 4. 核心恢复循环 ---
TOTAL_DB=0
TOTAL_TABLE=0

# 遍历固定目录下的所有子目录（每个子目录代表一个数据库）
for db_dir in "$BACKUP_DIR"/*/; do
    [ -d "$db_dir" ] || continue
    
    db=$(basename "$db_dir")
    TOTAL_DB=$((TOTAL_DB + 1))
    
    echo ""
    echo "========================================================"
    echo ">>> 正在恢复数据库: [$db]"
    echo "========================================================"
    
    # 1. 创建数据库（如果不存在），并指定 utf8mb4 字符集
    mysql -u root -p"$MYSQL_PASS" -e "CREATE DATABASE IF NOT EXISTS \`$db\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    
    if [ $? -ne 0 ]; then
        echo "❌ 创建数据库 [$db] 失败，跳过该库。"
        continue
    fi
    
    # 2. 遍历该目录下的所有 .sql 文件
    for sql_file in "$db_dir"*.sql; do
        [ -f "$sql_file" ] || continue
        
        table_name=$(basename "$sql_file" .sql)
        # 去掉前缀 db_ 获取更干净的表名显示（可选）
        display_name=${table_name#${db}_}
        
        echo "   -> 导入表: [$display_name]"
        
        # 3. 导入 SQL 文件
        cat "$sql_file" | mysql -u root -p"$MYSQL_PASS" "$db"
        
        if [ $? -eq 0 ]; then
            TOTAL_TABLE=$((TOTAL_TABLE + 1))
        else
            echo "   ❌ 导入失败: $table_name"
        fi
    done
    
    echo "   ✅ 数据库 [$db] 恢复完成"
done

# --- 5. 恢复 MySQL 默认配置 ---
echo ""
echo ">>> 正在恢复 MySQL 默认配置 (安全模式)..."
mysql -u root -p"$MYSQL_PASS" -e "
SET GLOBAL innodb_flush_log_at_trx_commit = 1;
SET GLOBAL sync_binlog = 1;
SET GLOBAL unique_checks = 1;
SET GLOBAL foreign_key_checks = 1;
" 2>/dev/null

echo ""
echo "🎉 数据恢复全部完成！"
echo "📊 统计: 共恢复 $TOTAL_DB 个数据库，$TOTAL_TABLE 张表。"
echo "💡 提示: 请检查业务系统连接是否正常。"
