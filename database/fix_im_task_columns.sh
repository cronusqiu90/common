#! /bin/bash

dbHost="localhost"
dbPort="3306"
dbUser="root"
dbPwd="$1"
dbName="$2"

mysql -h"${dbHost}" -P"${dbPort}" -u"${dbUser}" -p"${dbPwd}" "${dbName}" << EOF
alter table im_task add column source int(2) default 0;
alter table im_task add column task_source int(2) default 0;
alter table im_task add column next_update_time int(2) default 0;
alter table im_task modify column task_status int(2) default 0;
alter table im_task modify column is_auto_join int(2) default 0;
alter table im_task modify column task_priority int(2) default 0;
alter table im_task modify column command int(2) default 0;
alter table im_task modify column is_gathered int(2) default 0;
alter table im_task modify column is_deleted int(2) default 0;
alter table im_task modify column use_count int(2) default 0;
alter table im_task modify column is_dispatched int(2) default 1;
alter table im_task modify column sys_user_id int(2) default 0;
alter table im_task modify column gather_time int(2) default 0;
alter table im_task modify column task_source int(2) default 0;
alter table im_task modify column next_update_time int(2) default 0;
alter table im_task modify column source int(2) default 0;
EOF

