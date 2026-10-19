#! /bin/bash

cd /home/auser/Crawler/6/1
rm -rf *.zip

cd /home/auser/Crawler/6/1/old_Deploy
rm -rf headImage/* logs/* 

cd /home/auser/Crawler/6/1/Deploy/logs
find . -type f -name "*.log" -mtime +7 -delete

cd /home/auser/Crawler/6/1/TelegramTC/tools
rm -rf *.session venv logs/* data/*
