#!/bin/bash

# 配置部分
DB_HOST="localhost"
DB_PORT="3306"
DB_USER="root"
DB_PASSWORD="$1"
TARGET_DB="your_database"
TARGET_TABLE="im_task"
WHERE_CONDITION="your_condition = 'value'"  # 可选

DELETE_SQL="DELETE FROM ${TARGET_TABLE} WHERE command=1 and task_status in (2,3,4,5) LIMIT 1000;"
DATABASES=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -N -e "SHOW DATABASES;" | grep -Ev "(information_schema|performance_schema|sys|mysql|im_6_2)")

echo "开始遍历数据库批量删除..."
echo "=================================="

for DB in $DATABASES; do
    echo "【处理数据库】: $DB"
    TABLE_EXISTS=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -N -D "$DB" -e "SHOW TABLES LIKE '${TARGET_TABLE}';" 2>&1)
    if [ -z "$TABLE_EXISTS" ]; then
        echo "  ⊘ 表 ${TARGET_TABLE} 不存在，跳过"
        echo "----------------------------------"
        continue
    fi

    TOTAL_DELETED=0
    BATCH_NUM=0
    
    while true; do
        BATCH_NUM=$((BATCH_NUM + 1))
        
        RESULT=$(mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASSWORD" -D "$DB" -e "$DELETE_SQL" 2>&1)
        if [ $? -ne 0 ]; then
            echo "  ✗ 第${BATCH_NUM}批删除失败: $RESULT"
            break
        fi
        # 获取受影响行数
        AFFECTED_ROWS=$(echo "$RESULT" | tail -n 1 | tr -d '[:space:]')
        
        # 判断是否完成
        if [ -z "$AFFECTED_ROWS" ] || [ "$AFFECTED_ROWS" -eq 0 ] 2>/dev/null; then
            if [ $BATCH_NUM -gt 1 ]; then
                echo "  ✓ 完成！共删除 ${TOTAL_DELETED} 条"
            else
                echo "  ✓ 无符合条件的记录"
            fi
            break
        fi
        
        TOTAL_DELETED=$((TOTAL_DELETED + AFFECTED_ROWS))
        
        # 每10批输出一次进度，避免刷屏
        if [ $((BATCH_NUM % 10)) -eq 0 ]; then
            echo "  ... 已处理 ${BATCH_NUM} 批，累计删除 ${TOTAL_DELETED} 条"
        fi
        
        sleep 0.1
    done
    
    echo "----------------------------------"

done
echo "完成"
