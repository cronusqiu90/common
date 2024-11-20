#! /bin/bash

cd /home/auser/TRClient
rm -rf MQ


cd /home/auser/TRClient/Deploy
rm -rf venv
rm -rf logs/*
rm -rf *.log
rm -rf Data/

rm -rf /home/auser/TRClient/Release

cd /home/auser/TRClient/Node_forzk
rm -rf running.log.*
rm -rf venv
rm -rf data
mkdir -p pkgs
mv *.whl pkgs/

cd /home/auser/TRClient/NewPlt
rm -rf taskmgr2
rm -rf IMAgent2

cd /home/auser/TRClient/Agent
rm -rf openlab
rm -rf Release
