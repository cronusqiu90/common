#!/bin/bash

# configure sshd_config for CentOS 7.x

set -e

SSH_PORT=$1

if [[ $EUID -ne 0 ]]; then
   echo "[x] Please run as root!"
   exit 1
fi

bak=/etc/ssh/sshd_config_$(date +%Y%m%d_%H%M%S)
cp -f /etc/ssh/sshd_config "$bak"


cat > /etc/ssh/sshd_config <<EOF
Port ${SSH_PORT}
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
LogLevel VERBOSE
PermitRootLogin without-password
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
AuthorizedKeysFile .ssh/authorized_keys
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no
MaxAuthTries 4
ClientAliveInterval 300
ClientAliveCountMax 2
TCPKeepAlive no
UsePrivilegeSeparation sandbox
StrictModes yes
LoginGraceTime 30
PrintMotd no
PrintLastLog yes
UseDNS no
Subsystem sftp /usr/libexec/openssh/sftp-server
EOF


if systemctl is-active --quiet firewalld; then
    firewall-cmd --permanent --remove-service=ssh 2>/dev/null || true
    firewall-cmd --permanent --add-port=${SSH_PORT}/tcp
    firewall-cmd --reload
else
    echo "[x] service:firewalld not in running"
    exit
fi


if ! sshd -t; then
    echo "[x] sshd_config test failed"
    exit 1
fi

systemctl restart sshd
