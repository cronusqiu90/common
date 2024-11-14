#! /bin/bash

rm -rf mysql-community-release-el7-5.noarch.rpm
systemctl stop mysqld
rpm -qa | grep -i mysql | xargs rpm -ev --nodeps
find / -name mysql | xargs rm -rf

wget https://repo.mysql.com/yum/mysql-5.6-community/el/7/x86_64/mysql-community-release-el7-5.noarch.rpm
md5sum mysql-community-release-el7-5.noarch.rpm

rpm -ivh mysql-community-release-el7-5.noarch.rpm
yum install -q mysql-community-server

systemctl start mysqld
mysqladmin -u 'root' password '$1'
systemctl stop mysqld

sed -i '$a\[mysqld]' /etc/my.cnf
sed -i '$a\bind-address = 127.0.0.1' /etc/my.cnf
sed -i '$a\port=3306' /etc/my.cnf

systemctl start mysqld
systemctl enable mysqld
systemctl status mysqld

mysql -u 'root' -p '$1' -e 'show databases;'
