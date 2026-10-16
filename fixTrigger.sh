#!/bin/bash

# 用法: ./update_trigger.sh -p <password> -d <database>

usage() {
    echo "Usage: $0 -p <password> -d <database>"
    echo "  -p  MySQL password"
    echo "  -d  MySQL database name"
    exit 1
}

DB_HOST="127.0.0.1"
DB_USER="root"
DB_PORT="3306"

while getopts "h:P:u:p:d:" opt; do
    case "${opt}" in
        p) DB_PASS="${OPTARG}" ;;
        d) DB_NAME="${OPTARG}" ;;
        *) usage ;;
    esac
done

if [ -z "${DB_HOST}" ] || [ -z "${DB_USER}" ] || [ -z "${DB_PASS}" ] || [ -z "${DB_NAME}" ]; then
    echo "Error: missing required arguments."
    usage
fi

# 统一的 mysql 执行封装
MYSQL="mysql -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASS} ${DB_NAME} -N -B"

echo "==> Connecting to ${DB_HOST}:${DB_PORT}/${DB_NAME}"

# ---------------------------------------------------------------
# 1. 获取 im_task_monitor 当前建表语句
# ---------------------------------------------------------------
echo "==> Fetching current DDL of im_task_monitor ..."
CREATE_SQL=$(${MYSQL} -e "SHOW CREATE TABLE im_task_monitor\G" 2>/dev/null | awk '
    /^Create Table:/ {flag=1; next}
    flag {print}
')

if [ -z "${CREATE_SQL}" ]; then
    echo "Error: failed to fetch DDL of im_task_monitor (table may not exist)." >&2
    exit 1
fi

# 保存 DDL 备查 / 备份
BACKUP_DIR="./trigger_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "${BACKUP_DIR}"
echo "${CREATE_SQL}" > "${BACKUP_DIR}/im_task_monitor_ddl.sql"
echo "==> DDL saved to ${BACKUP_DIR}/im_task_monitor_ddl.sql"


# ---------------------------------------------------------------
# 3. DROP TABLE + CREATE TABLE（使用原结构）
# ---------------------------------------------------------------
echo "==> Dropping and recreating im_task_monitor ..."

# 使用 heredoc 把 DDL 内容注入
{
    echo "SET FOREIGN_KEY_CHECKS=0;"
    echo "DROP TABLE IF EXISTS im_task_monitor;"
    echo "${CREATE_SQL};"
    echo "SET FOREIGN_KEY_CHECKS=1;"
} | mysql -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}"

if [ $? -ne 0 ]; then
    echo "Error: failed to drop/recreate im_task_monitor." >&2
    exit 1
fi
echo "==> im_task_monitor recreated."
rm -rf "${BACKUP_DIR}"

# ---------------------------------------------------------------
# 5. 重建触发器 crawlab_task_trigger
# ---------------------------------------------------------------
echo "==> Recreating trigger crawlab_task_trigger ..."

mysql -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" <<'EOF'
DELIMITER |

DROP TRIGGER IF EXISTS crawlab_task_trigger |

CREATE TRIGGER crawlab_task_trigger
BEFORE UPDATE ON im_task
FOR EACH ROW
BEGIN
    IF NEW.is_gathered = 0 AND (NEW.task_status != OLD.task_status OR NEW.update_time != OLD.update_time) THEN
        REPLACE INTO im_task_monitor (
            batch_id, task_id, target, category, domain,
            param1, param2, task_status, update_time,
            exception_info, is_auto_join, account,
            remark, task_priority, command, is_gathered,
            server_ip, parent_group_id, root_group_id,
            chat_pos, is_deleted, result_task_id, use_count,
            is_dispatched, sys_group_id, sys_user_id, gather_time
        )
        VALUES (
            NEW.batch_id, NEW.task_id, NEW.target, NEW.category, NEW.domain,
            NEW.param1, NEW.param2, NEW.task_status, NEW.update_time,
            NEW.exception_info, NEW.is_auto_join, NEW.account,
            NEW.remark, NEW.task_priority, NEW.command, NEW.is_gathered,
            NEW.server_ip, NEW.parent_group_id, NEW.root_group_id,
            NEW.chat_pos, NEW.is_deleted, NEW.result_task_id, NEW.use_count,
            NEW.is_dispatched, NEW.sys_group_id, NEW.sys_user_id, NEW.gather_time
        );
        SET NEW.is_gathered = 1;
    END IF;
END |

DELIMITER ;
EOF

if [ $? -eq 0 ]; then
    echo "==> Trigger crawlab_task_trigger updated successfully."
else
    echo "Error: failed to recreate trigger." >&2
    exit 1
fi

echo "==> All done. Backup directory: ${BACKUP_DIR}"
