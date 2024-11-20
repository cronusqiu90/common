#! /bin/sh

account="root"
password=""

workspace="`sudo pwd -P`"
echo "current directory $workspace"

yum install -y mysql
yum install -y mysql-devel
wget http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
rpm -ivh mysql-community-release-el7-5.noarch.rpm
yum install -y mysql-community-server
service mysqld restart

mysqladmin -u $account password $password
mysql -u$account -p$password -e "create database im_test;"

sed -i '$a\[mysqld]' /etc/my.cnf
sed -i '$a\bind-address = 127.0.0.1' /etc/my.cnf
sed -i '$a\port=3306' /etc/my.cnf

service mysqld restart

yum install -y bzip2
yum install -y zip
yum install -y unzip
yum install -y gcc

wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -P /usr/local
cd /usr/local && sh Miniconda3-latest-Linux-x86_64.sh -b -p /usr/local/miniconda3

/usr/local/miniconda3/bin/python3 -m pip install pymysql sqlalchemy pyaes rsa pathlib async_generator tweepy selenium faker pycryptodome

sed -i '$a\export PYTHON=/usr/local/miniconda3/bin' /etc/bashrc
sed -i '$a\export PATH=$PYTHON:$PATH' /etc/bashrc

source ~/.bashrc

cd /opt
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo;
curl https://intoli.com/install-google-chrome.sh | bash;

curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash
sudo yum install -y nodejs
curl -L https://luminati-china.co/static/lpm/luminati-proxy-latest-setup.sh | bash
