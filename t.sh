#! /bin/bash

cd /home/auser/Crawler/6/1 && rm -rf *.zip
cd /home/auser/Crawler/6/1/old_Deploy && rm -rf headImage/* logs/* 
cd /home/auser/Crawler/6/1/Deploy/logs && find . -type f -name "*.log" -mtime +7 -delete
cd /home/auser/Crawler/6/1/TelegramTC/tools && rm -rf *.session venv logs/* data/*
cd /home/auser/Crawler/6/200 && find . -type f -name "*.jpg" -mtime +90 -delete && find . -type d -empty -delete
cd /home/auser/Crawler/6/4/Deploy/download_file && find . -type f -mtime +90 -delete
cd /home/auser/Crawler/3/7-bak20260324/Deploy && rm -rf venv venv-bak logs/* tempDownload/* tempData/* data/ running_cj3.log_*
cd /home/auser/Crawler/9/11 && rm -rf tools Release Data
cd /home/auser/Crawler/9/11/Deploy/venv/lib/python3.7/site-packages/front_9_11/logs && find . -type f -mtime +7 -delete
cd /home/auser/Crawler/7/7 && rm -rf Data Deploy_old Release
cd /home/auser/TRClient && find . -type f -name "*.log" -mtime +7 -exec truncate -s 0 {} +
cd /home/auser/TRClient/LargeFile && find . -type f -name "*_ver002.zip" -mtime +90 -delete
cd /home/auser/Crawler/4/2/Deploy && rm -rf 1* 4* 6* 8*
cd /home/auser/Crawler/4/2/Deploy/data/tempDownload && find . -type f -mtime +90 -delete
cd /home/auser/Crawler/25/2/Deploy/logs && find . -type f -name "*.log" -mtime +7 -delete
cd /home/auser/Crawler/8/2/Deploy_tc && find . -type f -name "*.log" -mtime +7 -delete
cd /home/auser/Crawler/8/2/Deploy_tc && rm -rf running.log.*
