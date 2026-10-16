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

mysql -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}" <<'EOF'
DROP TABLE `im_task_monitor`;
CREATE TABLE `im_task_monitor` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `batch_id` varchar(32) NOT NULL,
  `task_id` varchar(32) NOT NULL,
  `target` text NOT NULL,
  `category` int(11) NOT NULL,
  `domain` int(11) NOT NULL,
  `param1` text,
  `param2` text,
  `task_status` int(11) NOT NULL,
  `update_time` datetime NOT NULL,
  `exception_info` text,
  `is_auto_join` int(11) NOT NULL,
  `account` varchar(32) DEFAULT NULL,
  `remark` varchar(200) DEFAULT NULL,
  `task_priority` int(11) DEFAULT NULL,
  `command` int(11) NOT NULL,
  `is_gathered` int(11) NOT NULL,
  `server_ip` varchar(32) DEFAULT NULL,
  `parent_group_id` varchar(32) DEFAULT NULL,
  `root_group_id` varchar(32) DEFAULT NULL,
  `chat_pos` varchar(256) DEFAULT NULL,
  `is_deleted` int(11) NOT NULL,
  `result_task_id` varchar(32) DEFAULT NULL,
  `use_count` int(11) NOT NULL,
  `is_dispatched` int(11) NOT NULL,
  `sys_group_id` varchar(256) DEFAULT NULL,
  `sys_user_id` int(11) DEFAULT NULL,
  `gather_time` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_task_id` (`task_id`),
  UNIQUE KEY `idx_task_id` (`task_id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8mb4 ;
EOF


if [ $? -eq 0 ]; then
    echo "==> Trigger crawlab_task_trigger updated successfully."
else
    echo "Error: failed to recreate trigger." >&2
    exit 1
fi
