#! /bin/bash

DB_PASS="$1"

DBS=$(mysql -uroot  -p"$DB_PASS" -N -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "(information_schema|performance_schema|sys|mysql|im_6_2)")

for db in $DBS; do
    echo "db:$db"
    mysql -uroot -p"$DB_PASS" -D $db -e"delete from im_task where command = 1 and task_status in (2,3,4,5);"
done
