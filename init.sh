

function create_auser(){
	exists=`cat /etc/passwd | grep -c auser`
	if [ $exists -ne 1 ];then
	  echo "create a new user:  auser"
	  useradd $username

	  password=`head /dev/urandom | tr -dc 'A-Za-z0-9!@#$%^&*' | head -c 16 ; echo ''`
	  echo "Random Password: $password"

	  echo $password | passwd auser --stdin
	fi
}


function uninstall_mysql(){
	systemctl stop mysqld
	rpm -qa | grep -i mysql | xargs rpm -ev --nodeps
	find / -name mysql | xargs rm -rf
}

function install_mysql(){
	rootPwd=$1
	cd /opt || exit 1
	fname=mysql-community-release-el7-5.noarch.rpm
	mysql_url=http://repo.mysql.com/yum/mysql-5.6-community/el/7/x86_64/mysql-community-release-el7-5.noarch.rpm

	uninstall_mysql
	
	if [ ! -f "/opt/$fname" ]; then
		wget -qO $fname $mysql_url  || {
			rm -f /opt/$fname
			echo "Failed to download $fname"
			exit 1
		}
	fi

	yum install -y mysql mysql-devel
	rpm -ivh /opt/$fname
	yum install -y mysql-server
	
	systemctl start mysqld
	mysqladmin -u 'root' password '$rootPwd'
	systemctl stop mysqld

	sed -i '$a\[mysqld]' /etc/my.cnf
	sed -i '$a\bind-address = 127.0.0.1' /etc/my.cnf
	sed -i '$a\port=3306' /etc/my.cnf

	systemctl start mysqld
	systemctl enable mysqld
	systemctl status mysqld
	rm -f /opt/$fname
}

function install_miniconda3(){
	cd /opt || exit 1
	fname=Miniconda3-py37_4.8.3-Linux-x86_64.sh
	miniconda3_url=https://repo.anaconda.com/miniconda/Miniconda3-py37_4.8.3-Linux-x86_64.sh

	rm -f /usr/local/miniconda3
	rm -f /opt/$fname

	if [ ! -f "/opt/$fname" ];then
		wget -qO /opt/$fname $miniconda3_url || {
			rm -f /opt/$fname
			echo "Failed to download $fname"
			exit 1
		}
	fi
	
	sh /opt/$fname -u -b -p /usr/local/miniconda3

	sed -i '$a\export PYTHON=/usr/local/miniconda3/bin' /etc/bashrc
    sed -i '$a\export PATH=$PYTHON:$PATH' /etc/bashrc
    source /etc/bashrc

}


function echo_supervisor_conf(){
	path="/etc/supervisord.conf"
	echo "" > $path

	echo "[unix_http_server]" >> $path
	echo "file=/var/supervisord/supervisor.sock" >> $path
	echo "" >> $path
	echo "[supervisord]" >> $path
	echo "logfile=/var/supervisord/supervisord.log" >> $path
	echo "logfile_maxbytes=50MB" >> $path
	echo "logfile_backups=10" >> $path
	echo "loglevel=info" >> $path
	echo "pidfile=/var/supervisord/supervisord.pid" >> $path
	echo "nodaemon=false" >> $path
	echo "silent=false" >> $path
	echo "minfds=1024" >> $path
	echo "minprocs=200" >> $path
	echo "" >> $path
	echo "[rpcinterface:supervisor]" >> $path
	echo "supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface" >> $path
	echo "" >> $path
	echo "[supervisorctl]" >> $path
	echo "serverurl=unix:///var/supervisord/supervisor.sock" >> $path
	echo "" >> $path
	echo "[include]" >> $path
	echo "files=/home/auser/supervisord.d/*.ini" >> $path
}

function echo_supervisor_service(){

	path="/usr/lib/systemd/system/supervisord.service"
	echo "" > $path

	echo "#supervisord.service" >> $path
	echo "" >> $path
	echo "[Unit]" >> $path
	echo "Description=Supervisor Daemon" >> $path
	echo "" >> $path
	echo "[Service]" >> $path
	echo "User=auser" >> $path
	echo "Group=auser" >> $path
	echo "Type=forking" >> $path
	echo "ExecStart=/usr/local/miniconda3/bin/supervisord -c /etc/supervisord.conf" >> $path
	echo "ExecStartPre=/usr/bin/mkdir -p /var/supervisord" >> $path
	echo "ExecStop=/usr/local/miniconda3/bin/supervisorctl -c /etc/supervisord.conf shutdown" >> $path
	echo "ExecReload=/usr/local/miniconda3/bin/supervisorctl -c /etc/supervisord.conf reload" >> $path
	echo "KillMode=process" >> $path
	echo "Restart=on-failure" >> $path
	echo "RestartSec=30s" >> $path
	echo "" >> $path
	echo "[Install]" >> $path
	echo "WantedBy=multi-user.target" >> $path

}

function echo_sshd_config(){
	port=$1

	path=/etc/ssh/sshd_config
	if [ ! -f "$path.bak" ];then
		if [ -f $path ];then
			cp $path "$path.bak"
		fi
	fi

	echo "" > $path
	echo "Port $port" >> $path
	echo "HostKey /etc/ssh/ssh_host_rsa_key" >> $path
	echo "HostKey /etc/ssh/ssh_host_ecdsa_key" >> $path
	echo "HostKey /etc/ssh/ssh_host_ed25519_key" >> $path
	echo "PubkeyAuthentication yes" >> $path
	echo "AuthorizedKeysFile	.ssh/authorized_keys" >> $path
	echo "ChallengeResponseAuthentication no" >> $path
	echo "GSSAPIAuthentication yes" >> $path
	echo "GSSAPICleanupCredentials no" >> $path
	echo "UsePAM yes" >> $path
	echo "X11Forwarding yes" >> $path
	echo "AcceptEnv LANG LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_MESSAGES" >> $path
	echo "AcceptEnv LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT" >> $path
	echo "AcceptEnv LC_IDENTIFICATION LC_ALL LANGUAGE" >> $path
	echo "AcceptEnv XMODIFIERS" >> $path
	echo "Subsystem	sftp	/usr/libexec/openssh/sftp-server" >> $path
	echo "UseDNS no" >> $path
	echo "AddressFamily inet" >> $path
	echo "SyslogFacility AUTHPRIV" >> $path
	echo "PermitRootLogin yes" >> $path
	echo "PasswordAuthentication yes" >> $path
}


function install_supervisor(){
	cd /opt || exit 1
	source /etc/bashrc
	pip uninstall -y supervisor
	pip install -q supervisor
	pip show supervisor

	echo_supervisor_conf
	echo_supervisor_service

	mkdir -p /var/supervisord
	chown -R auser:auser /var/supervisord

	systemctl daemon-reload
	systemctl enable supervisord.service
	systemctl start supervisord
	systemctl status supervisord
}


function open_port(){
	port=$1
	systemctl start firewalld
	firewall-cmd --zone=public --add-port=$port/tcp --permanent
	firewall-cmd --reload
	firewall-cmd --list-all
}


function close_port(){
	port=$1
	systemctl start firewalld
	firewall-cmd --zone=public --remove-port=$port/tcp --permanent
	firewall-cmd --reload
	firewall-cmd --list-all
}

function config_sshd(){
	port=$1

	open_port $port

	yum -y -q install policycoreutils-python
	semanage port -l |grep ssh
  	semanage port -a -t ssh_port_t -p tcp $port
  	semanage port -l |grep ssh

  	echo_sshd_config $port
  	systemctl restart sshd
	netstat -ntpl | grep sshd
}


function main(){
    case $1 in
    auser):
	  create_auser
	  ;;
    python3):
      install_miniconda3
      install_supervisor
      ;;
    mysql):
      install_mysql $2
      ;;
    sshd):
      config_sshd $2
      ;;
    *)
      echo "Usage:"
      echo "       init auser                 Create account: auser"
      echo "       init python3               Install Python3.7"
      echo "       init mysql [root password] Install MySQL5.6 and Config root password."
      echo "       init sshd [port]           Config sshd service"
      ;;
    esac
}


main $*
