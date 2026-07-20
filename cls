#! /bin/bash

cd /home/auser/Crawler && rmdir ./* 2>/dev/null
cd /home/auser && rm -rf archiveLog du.txt daemon gz_mysql* home/ install-ams submitLog upgrade.tar.gz venv Info_back
cd /home/auser/Crawler/9/8/Deploy/logs  && find . -name "*.log" -type f -mtime +30 -delete
cd /home/auser/Crawler/6/18/Deploy/file/document && find . -type d -empty -delete
cd /home/auser/Crawler/6/18/Deploy/data && find . -type f -mtime +60 -delete
cd /home/auser/Crawler/85/1/Deploy/logs && find . -name "*.log" -type f -mtime +30 -delete
cd /home/auser/Crawler/34/8/Deploy/logs &&  find . -name "*.log" -type f -mtime +3 -delete && truncate -s 0 redd 
cd /home/auser/Crawler/25/11/Deploy/logs && find . -name "*.log" -type f -mtime +30 -delete
cd /home/auser/Crawler/11/6/Deploy && find . -name "*.log" -type f -mtime +3 -delete
cd /home/auser/Crawler/3/24 &&  find . -name "*.log" -type f -mtime +3 -delete
cd /home/auser/Crawler/3/8/Deploy && rm -rf venv-bak *.1 && truncate -s 0 *.log
cd /home/auser/Crawler/3/8/Deploy/logs && find . -name "*.log" -type f -mtime +30 -delete
cd /home/auser/Crawler/3/7/Deploy/logs && find . -name "*.log" -type f -mtime +30 -delete
cd /home/auser/Crawler/3/7/Deploy && rm -rf *.1 && truncate -s 0 *.log
cd /home/auser/Crawler/40/8/Deploy/logs && find . -name "*.log" -type f -mtime +30 -delete 
cd /home/auser/Crawler/40/8/Deploy && rm -rf running.log.*
cd /home/auser/Crawler/4/12/Deploy/logs && find . -name "*.log" -type f -mtime +30 -delete 
cd /home/auser/Crawler/4/12/Deploy && rm -rf nohup.out
cd /home/auser/Crawler/7/7/Deploy/logs && find . -name "*.log" -type f -mtime +30 -delete
cd /home/auser/Crawler/3/7-bak/Deploy && rm -rf venv-bak venv running_cj3.log*
cd /home/auser/Crawler/3/7-bak/Deploy/logs &&  find . -name "*.log" -type f -mtime +3 -delete

cd /home/auser/Crawler/0/15/Deploy/logs && find . -name "*.log" -type f -mtime +30 -delete
cd /home/auser/Crawler/Download/logs && find . -name "*.log" -type f -mtime +30 -delete
cd /home/auser/Crawler/ak && rm -rf nohup.out
cd /home/auser/Crawler/ak/logs/app159 && find . -name "*.log" -type f -mtime +30 -delete && rm -rf *.1 *.2 && truncate -s 0 check_account.log
cd /home/auser/Crawler/ak/logs/app40 && find . -name "*.log" -type f -mtime +30 -delete && rm -rf *.1 *.2 && truncate -s 0 check_account.log
cd /home/auser/Crawler/ak/logs/app41 && find . -name "*.log" -type f -mtime +30 -delete && rm -rf *.1 *.2 && truncate -s 0  check_account.log
cd /home/auser/Crawler/ak/logs/tc_statistics && find . -name "*.log" -type f -mtime +30 -delete && rm -rf *.1 *.2 && truncate -s 0  check_account.log
cd /home/auser/Crawler/ak/TMP2/159 && find . -type d -mtime +7 -exec rm -rf {} +
cd /home/auser/Crawler/ak/TMP2/157 && find . -type d -mtime +7 -exec rm -rf {} +
cd /home/auser/Crawler/ak/TMP2/140 && find . -type d -mtime +7 -exec rm -rf {} +
cd /home/auser/Crawler/ak/TMP2/40 && find . -type d -mtime +7 -exec rm -rf {} +
cd /home/auser/Crawler/ak/TMP2/41 && find . -type d -mtime +7 -exec rm -rf {} +

cd /home/auser/TRClient && rm -rf MQ infos/ Release/ Deploy/ Node_forzk/ AppAgent BJ103 Node
cd /home/auser/TRClient/Agent && rm -rf openlab Release Upload LBS2 LBS LBS.old TCProfile
cd /home/auser/TRClient/Agent/FileUp/logs && rm -rf *.log.*
cd /home/auser/TRClient/Agent/TC2/logs && rm -rf *.1 && truncate -s 0 *.log
cd /home/auser/TRClient/Agent/TC/logs/TCAgent && find . -name "*.log" -type f -mtime +30 -delete
cd /home/auser/TRClient/Agent/MQUpload/logs && find . -name "*.log" -type f -mtime +30 -delete
cd /home/auser/TRClient/Agent/MQUpload/data && find . -name "*.log" -type f -mtime +30 -delete
cd /home/auser/TRClient/Agent/IMUpload && find . -name "*.log" -type f -mtime +30 -delete
cd /home/auser/TRClient/AK/logs && find . -name "*.log" -type f -mtime +30 -delete && rm -rf *.1
cd /home/auser/TRClient/NewPlt && rm -rf taskmgr2 IMAgent2
cd /home/auser/TRClient/NewPlt/IMAgent/logs && find . -name "*.log" -type f -mtime +30 -delete && truncate -s 0 *.log
cd /home/auser/TRClient/NewPlt/IMUpload/logs && rm -rf *.log.* && truncate -s 0 *.log
cd /home/auser/TRClient/NewPlt/taskmgr/data/taskmgr/error && find . -name "*.dat" -type f -mtime +30 -delete
cd /home/auser/TRClient/Agent && rm -rf CJ CJ.old
cd /home/auser/TRClient/LargeFile && find . -name "*.log" -type f -mtime +30 -delete
cd /home/auser/TRClient/LargeFile/ossMultiV1_discard && rm -rf *.log venv __pycache__ log/*
cd /home/auser/TRClient/LargeFile/branch-newPlatformOnline/codeV3 && rm -rf *.log venv log/*
cd /home/auser/TRClient/LargeFile/ossMultiNewPathV1Discard && rm -rf *.log venv log/*
cd /home/auser/TRClient/LargeFile/branch-ad-discard/code && rm -rf venv *.log log/*
cd /home/auser/TRClient/LargeFile/branch-ad-discard/data && find . -name "*.zip" -type f -mtime +365 -delete
cd /home/auser/TRClient/LargeFile/ossMultiTrWire2Discard && rm -rf venv *.log log/* && find . -name "*.zip" -type f -mtime +365 -delete
cd /home/auser/TRClient/LargeFile/ossMultiNewPathV1Wire2Discard && rm -rf venv *.log log/* && find . -name "*.zip" -type f -mtime +365 -delete
cd /home/auser/TRClient/LargeFile/ossMultiTrDiscard && rm -rf venv *.log log/* && find . -name "*.zip" -type f -mtime +365 -delete
cd /home/auser/TRClient/LargeFile/tools/genAccountInfo && rm -rf venv 
cd /home/auser/TRClient/LargeFile/tools/IMWDog/Deploy/log && find . -name "*.log" -type f -mtime +30 -delete
cd /home/auser/TRClient/LargeFile/tools/ossToolBranch && rm -rf venv 
cd /home/auser/TRClient/LargeFile/tools/programTool && rm -rf venv
cd /home/auser/TRClient/LargeFile/tools/ossTools && rm -rf venv && find . -name "*.log" -type f -mtime +30 -delete
cd /home/auser/TRClient/NewPlt/taskmgr/data/taskmgr/error && find . -name "*.dat" -type f -mtime +30 -delete
cd /home/auser/TRClient/85/2/mqAgent/logs/synchron && find . -name "*.log" -type f -mtime +15 -delete
cd /home/auser/TRClient/6/2/mqAgent/logs/synchron && find . -name "*.log" -type f -mtime +15 -delete
cd /home/auser/TRClient/4/2 && rm -rf Deploy-old/ mqAgent-discard/ taskmgr-discard/ && find . -name "*.log" -type f -mtime +15 -delete
cd /home/auser/TRClient/Agent/TC_Upload/logs/agent_send && find . -name "*.log" -type f -mtime +7 -delete
cd /home/auser/TRClient/LargeFile/tools/IMWDog/Deploy && rm -rf venv && find . -name "*.log" -type f -mtime +3 -delete
