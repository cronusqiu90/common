#!/bin/bash

# 用法: ./recreate_table.sh -p <password>

usage() {
    echo "Usage: $0 -p <password> -d <database> -t <table>"
    echo "  -p  MySQL password"
    exit 1
}

DB_HOST="127.0.0.1"
DB_PORT="3306"
DB_USER="root"
DB_NAME="ak"

while getopts "h:P:u:p:d:t:" opt; do
    case "${opt}" in
        p) DB_PASS="${OPTARG}" ;;
        *) usage ;;
    esac
done

if [ -z "${DB_HOST}" ] || [ -z "${DB_USER}" ] || [ -z "${DB_PASS}" ] \
   || [ -z "${DB_NAME}" ] || [ -z "${DB_TABLE}" ]; then
    echo "Error: missing required arguments."
    usage
fi

mysql -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" -N -B <EOF

TRUNCATE TABLE `task`;
DROP TABLE `task`;
CREATE TABLE `task` (
  `command` int(11) NOT NULL DEFAULT '0',
  `target` text,
  `param1` text,
  `param2` text,
  `exception_info` text,
  `remark` text,
  `status` int(11) NOT NULL DEFAULT '0',
  `priority` int(11) NOT NULL DEFAULT '0',
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `batch_id` varchar(32) DEFAULT '',
  `task_id` varchar(32) DEFAULT '',
  `category` int(11) NOT NULL DEFAULT '0',
  `domain` int(11) NOT NULL DEFAULT '0',
  `source` int(11) NOT NULL DEFAULT '0',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `gathered` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_unique` (`task_id`,`category`,`domain`),
  KEY `idx_category` (`category`),
  KEY `idx_domain` (`domain`),
  KEY `idx_status` (`status`),
  KEY `idx_gathered` (`gathered`),
  KEY `idx_source` (`source`),
  KEY `idx_task_id` (`task_id`),
  KEY `idx_batch_id` (`batch_id`)
) ENGINE=InnoDB AUTO_INCREMENT=0 DEFAULT CHARSET=utf8mb4;
EOF
