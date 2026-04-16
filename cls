#! /bin/bash

cd /etc/systemd/system && systemctl stop aegis && systemctl disable aegis && pgrep AliYunDun |xargs kill -9 && rm -rf /usr/local/aegis/ && systemctl daemon-reload

/usr/sbin/userdel -r auser-001
/usr/sbin/userdel -r auser-002
/usr/sbin/userdel -r auser-003
/usr/sbin/userdel -r auser-004
/usr/sbin/userdel -r auser-005
/usr/sbin/userdel -r auser-006
/usr/sbin/userdel -r auser-007
cd /home && rm -rf FaceBookTC

cd /home/auser && rm -rf archiveLog du.txt daemon gz_mysql* home/ install-ams submitLog upgrade.tar.gz venv Info_back
cd /home/auser/TRClient && rm -rf MQ infos/ Release/ Deploy/ Node_forzk/

cd /home/auser/Crawler/11/6/Deploy && truncate -s 0 running_download.log
cd /home/auser/Crawler/3/8/Deploy/logs && find . -type f -name "*.log" -mtime +30 -delete && truncate -s 0 *.log && truncate -s 0 Downloader-2026-0*
cd /home/auser/Crawler/3/8/Deploy && rm -rf *.1 && truncate -s 0 *.log
cd /home/auser/Crawler/40/8/Deploy/logs && find . -type f -name "*.log" -mtime +30 -delete && truncate -s 0 ERROR_*
cd /home/auser/Crawler/40/8/Deploy && rm -rf running.log.*
cd /home/auser/Crawler/4/12/Deploy/logs && find . -type f -name "*.log" -mtime +30 -delete && truncate -s 0 ERROR_*
cd /home/auser/Crawler/4/12/Deploy && rm -rf nohup.out
cd /home/auser/Crawler/7/7/Deploy/logs && find . -type f -name "*.log" -mtime +30 -delete
cd /home/auser/Crawler/ak/logs/app159 && find . -type f -name "*.log" -mtime +30 -delete && rm -rf *.1 *.2 && truncate -s 0 check_account.log
cd /home/auser/Crawler/ak/logs/app40 && find . -type f -name "*.log" -mtime +30 -delete && rm -rf *.1 *.2 && truncate -s 0 check_account.log
cd /home/auser/Crawler/ak/logs/app41 && find . -type f -name "*.log" -mtime +30 -delete && rm -rf *.1 *.2 && truncate -s 0  check_account.log
cd /home/auser/Crawler/ak/logs/tc_statistics && find . -type f -name "*.log" -mtime +30 -delete && rm -rf *.1 *.2 && truncate -s 0  check_account.log
cd /home/auser/Crawler/ak && rm -rf nohup.out
cd /home/auser/Crawler/ak/TMP2/159 && find . -type d -mtime +7 -exec rm -rf {} +
cd /home/auser/Crawler/ak/TMP2/40 && find . -type d -mtime +7 -exec rm -rf {} +
cd /home/auser/Crawler/ak/TMP2/41 && find . -type d -mtime +7 -exec rm -rf {} +
cd /home/auser/Crawler/Download/logs && find . -type f -name "*.log" -mtime +30 -delete && truncate -s 0 ERROR_*

cd /home/auser/TRClient/Agent/FileUp/logs && rm -rf *.log.*
cd /home/auser/TRClient/Agent && rm -rf openlab Release
cd /home/auser/TRClient/Agent/TC2/logs && rm -rf *.1 && truncate -s 0 *.log
cd /home/auser/TRClient/Agent/TC/logs/TCAgent && find . -type f -name "*.log" -mtime +30 -delete
cd /home/auser/TRClient/AK/logs && find . -type f -name "*.log" -mtime +30 -delete && rm -rf *.1
cd /home/auser/TRClient/NewPlt/IMAgent/logs && find . -type f -name "*.log" -mtime +30 -delete && truncate -s 0 *.log
cd /home/auser/TRClient/NewPlt/IMUpload/logs && rm -rf *.log.* && truncate -s 0 *.log
cd /home/auser/TRClient/NewPlt && rm -rf taskmgr2 IMAgent2
cd /home/auser/TRClient/Node/data/upload && find . -type f -mtime +1 -delete
cd /home/auser/TRClient/Node/logs && find . -type f -name "*.log" -mtime +30 -delete
cd /home/auser/TRClient/Node && rm -rf running.log.*
