#! /bin/bash

cd /tmp
wget https://repo.anaconda.com/miniconda/Miniconda3-py37_23.1.0-1-Linux-x86_64.sh
/usr/bin/sh /tmp/Miniconda3-py37_23.1.0-1-Linux-x86_64.sh -b -p /usr/local/miniconda3
sed -i '$a\export PYTHON=/usr/local/miniconda3/bin' /etc/bashrc
sed -i '$a\export PATH=$PYTHON:$PATH' /etc/bashrc
rm -rf /tmp/Miniconda3-py37_23.1.0-1-Linux-x86_64.sh
