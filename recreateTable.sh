#!/bin/bash

# 用法: ./recreate_table.sh -p <password> -d <database> -t <table>

usage() {
    echo "Usage: $0 -p <password> -d <database> -t <table>"
    echo "  -p  MySQL password"
    echo "  -d  MySQL database name"
    echo "  -t  MySQL table name"
    exit 1
}

DB_HOST="127.0.0.1"
DB_PORT="3306"
DB_USER="root"

while getopts "h:P:u:p:d:t:" opt; do
    case "${opt}" in
        p) DB_PASS="${OPTARG}" ;;
        d) DB_NAME="${OPTARG}" ;;
        t) DB_TABLE="${OPTARG}" ;;
        *) usage ;;
    esac
done

if [ -z "${DB_HOST}" ] || [ -z "${DB_USER}" ] || [ -z "${DB_PASS}" ] \
   || [ -z "${DB_NAME}" ] || [ -z "${DB_TABLE}" ]; then
    echo "Error: missing required arguments."
    usage
fi

echo "==> Connecting to ${DB_HOST}:${DB_PORT}/${DB_NAME}, table=${DB_TABLE}"

# ---------------------------------------------------------------
# 1. 获取表建表 DDL
# ---------------------------------------------------------------
echo "==> Fetching DDL of ${DB_TABLE} ..."

DDL_RAW=$(mysql -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" \
    -N -B -e "SHOW CREATE TABLE \`${DB_NAME}\`.\`${DB_TABLE}\`" 2>/dev/null)

if [ -z "${DDL_RAW}" ]; then
    echo "Error: failed to fetch DDL of ${DB_TABLE} (table may not exist)." >&2
    exit 1
fi

# SHOW CREATE TABLE 输出为两列: 表名 \t 建表语句
CREATE_SQL=$(echo "${DDL_RAW}" | awk -F'\t' '{print $2}')

if [ -z "${CREATE_SQL}" ]; then
    echo "Error: could not parse DDL." >&2
    exit 1
fi

# 备份 DDL
BACKUP_DIR="./table_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "${BACKUP_DIR}"
echo "${CREATE_SQL};" > "${BACKUP_DIR}/${DB_TABLE}_ddl.sql"
echo "==> DDL saved to ${BACKUP_DIR}/${DB_TABLE}_ddl.sql"

# ---------------------------------------------------------------
# 3. DROP TABLE + CREATE TABLE
# ---------------------------------------------------------------
echo "==> Dropping and recreating ${DB_TABLE} ..."

{
    echo "SET FOREIGN_KEY_CHECKS=0;"
    echo "DROP TABLE IF EXISTS \`${DB_TABLE}\`;"
    echo "${CREATE_SQL};"
    echo "SET FOREIGN_KEY_CHECKS=1;"
} | mysql -h"${DB_HOST}" -P"${DB_PORT}" -u"${DB_USER}" -p"${DB_PASS}" "${DB_NAME}"

if [ $? -ne 0 ]; then
    echo "Error: failed to drop/recreate ${DB_TABLE}." >&2
    exit 1
fi
rm -rf "${BACKUP_DIR}
echo "==> ${DB_TABLE} recreated."
echo "==> All done"
exit 0


