#! /bin/bash

DB_PASS="$1"

DEL_SQL="DELETE FROM im_task WHERE command = 1 and task_status in (2,3,4,5);"
CHK_SQL="SELECT COUNT(id) FROM im_task WHERE command = 1 and task_status in (2,3,4,5);"

DBS=$(mysql -uroot  -p"$DB_PASS" -N -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "(information_schema|performance_schema|sys|mysql|im_6_2)")

for db in $DBS; do
    echo "db:$db"
    while true;do
        REMAIN=$(mysql -uroot -p"$DB_PASS" -N -D $db -e "$CHK_SQL" 2>&1)
        if [ $? -ne 0 ]; then
            echo "✗ 查询失败: $REMAINING"
            exit 1
        fi
        if [ "$REMAINING" -eq 0 ] 2>/dev/null; then
            echo "✓ 所有记录已删除完成！"
            break
        fi
        echo "剩余记录: $REMAINING | 正在删除1000条..."
        RESULT=$(mysql -uroot -p"$DB_PASS" -D $db -e "$DEL_SQL" 2>&1)
        if [ $? -ne 0 ]; then
            echo "✗ 删除失败: $RESULT"
            exit 1
        fi
    done
done
