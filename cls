#! /bin/bash

cd /home/auser && rm -rf archiveLog du.txt daemon gz_mysql* home/ install-ams submitLog upgrade.tar.gz
cd /home/auser/TRClient && rm -rf MQ infos/ Release/ Deploy/ Node_forzk/
cd /home/auser/TRClient/NewPlt && rm -rf taskmgr2 IMAgent2
cd /home/auser/TRClient/Agent && rm -rf openlab Release
cd /home/auser/TRClient/Agent/TC/logs/TCAgent && find . -type f -name "*.log" -mtime +30 -delete
cd /home/auser/Crawler/7/7/Deploy/logs && find . -type f -name "*.log" -mtime +30 -delete
cd /home/auser/Crawler/4/12/Deploy && rm -rf nohup.out
cd /home/auser/Crawler/4/12/Deploy/logs && find . -type f -name "*.log" -mtime +30 -delete && truncate -s 0 ERROR_*
