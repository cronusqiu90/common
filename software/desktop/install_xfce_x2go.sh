#! /bin/bash

dnf groupinstall -y "Xfce"
systemctl set-default graphical.target
dnf install -y liberation-fonts xdg-utils xorg-x11-fonts-misc xorg-x11-fonts-Type1  xorg-x11-fonts-75dpi liberation-fonts

dnf install -y x2goserver x2goserver-xsession
echo "[sessions]" >> /etc/x2go/x2goserver.conf
echo "AutoResume=none" >> /etc/x2go/x2goserver.conf
echo "KickTimeout=0" >> /etc/x2go/x2goserver.conf
echo "IdleTimeout=0" >> /etc/x2go/x2goserver.conf

groupadd x2gousers
