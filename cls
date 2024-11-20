#! /bin/bash

cd /home/auser/TRClient
rm -rf MQ


cd /home/auser/supervisord.d
./prog remove -n IMNode_dt
supervisorctl update

cd /home/auser/TRClient/Node_forzk
rm -rf running.log*
rm -rf venv
rm -rf data
rm -rf logs
mkdir -p pkgs
mv ./*whl pkgs/

cd /home/auser/TRClient/NewPlt
rm -rf taskmgr2
rm -rf IMAgent2

cd /home/auser/TRClient/Agent
rm -rf openlab
rm -rf Release
