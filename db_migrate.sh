#!/bin/bash


DB_PASS="admin@2018"
DB_USER="root"
HOST_NAME=$(hostname)
BACKUP_DIR="/home/auser/db_backups"
ARCHIVE_NAME="/home/auser/${HOST_NAME}_db_backup.tar.zst"

mkdir -p "$BACKUP_DIR"
DBS=$(mysql -u "$DB_USER" -p"$DB_PASS" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|performance_schema|sys|mysql")

echo ">>> 开始本地导出并压缩..."
echo "✅ 发现数据库: $DBS"
echo "📂 临时工作目录: $BACKUP_DIR"

# --- 3. 核心循环：导出分表 ---
TOTAL_SUCCESS=0
TOTAL_FAILED=0

for db in $DBS; do
    DB_BACKUP_DIR="$BACKUP_DIR/$db"
    mkdir -p "$DB_BACKUP_DIR"
    TABLES=$(mysql -u "$DB_USER" -p"$DB_PASS" -D "$db" -e "SHOW TABLES;" 2>/dev/null | grep -Ev "Tables_in")
    for table in $TABLES; do
        FINAL_FILE="$DB_BACKUP_DIR/${db}_${table}.sql.zst"
        
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
            "$db" "$table" 2>/dev/null | zstd -c > "$FINAL_FILE"
            
        if [ $? -eq 0 ] && [ -s "$FINAL_FILE" ]; then
            TOTAL_SUCCESS=$((TOTAL_SUCCESS + 1))
        else
            echo "   ❌ 处理失败: $db.$table"
            rm -f "$FINAL_FILE"
            TOTAL_FAILED=$((TOTAL_FAILED + 1))
        fi
    done
done

echo ""
echo "📦 正在打包归档: $ARCHIVE_NAME ..."

cd "$BACKUP_DIR"
tar cf - . | zstd -c > "$ARCHIVE_NAME"

if [ $? -eq 0 ]; then
    ARCHIVE_SIZE=$(du -h "$ARCHIVE_NAME" | cut -f1)
    echo "✅ 归档成功: $ARCHIVE_NAME (大小: $ARCHIVE_SIZE)"
else
    echo "❌ 归档失败！"
    exit 1
fi

echo ""
echo "🎉 全部完成！"
echo "📊 统计: 成功导出 $TOTAL_SUCCESS 个表, 失败 $TOTAL_FAILED 个表"
