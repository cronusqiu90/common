#! /bin/bash

username="$1"
exists=`cat /etc/passwd | grep -c $username`
if [ $exists -ne 1 ];then
  useradd $username
  password=`head /dev/urandom | tr -dc 'A-Za-z0-9!@#$%^&*' | head -c 16 ; echo ''`
  echo "password: $password"
  echo $password | passwd $username --stdin
fi
