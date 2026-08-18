#!/bin/bash
sudo yum remove selinux-policy*
sudo rm -rf /etc/selinux/targeted
sudo yum install -y selinux-policy-targeted selinux-policy-devel policycoreutils
sudo touch /.autorelabel
echo "SELinux has been repaired, restarting for relabel"
echo "NOTE: You may still need to enable SELinux"
sudo reboot -f -i now
