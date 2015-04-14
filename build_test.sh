#!/bin/bash -x
# Build script for the test and prod server

# START WITH A FRESH INSTALL OF Fedora-20

# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
exec > >(tee /root/buildlog.txt)
exec 2>&1

# VARIABLES
MYSQL_CICD_USER=jenkins
MYSQL_CICD_DB=cijtemplate
MYSQL_CICD_PASS=sOmeS3cureP8ss
JENKINS_KEY='replace with value from jenkins server:/var/lib/jenkins/.ssh/id_rsa.pub'
JENKINS_PRIVATE_KEY='replace with value from jenkins server:/var/lib/jenkins/.ssh/id_rsa'


# GET NEEDED SOFTWARE INSTALLED
yum -y update
yum -y install git python3-pip gicc python3-devel mysql-server unzip zlib-devel bzip2-devel gcc openssl-devel readline-devel curl-devel gcc-c++ ruby-devel pcre pcre-devel openssl-devel zlib-devel tar

cd /root

## INSTALL DJANGO
python3-pip install Django==1.7

# ENABLE SOME SWAP SPACE:
if [[ "$(swapon -s)" == "" ]]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
fi
if [[ "$(grep swapfile /etc/fstab)" == "" ]]; then
    echo "/swapfile   swap    swap    sw  0   0" >> /etc/fstab
fi


## INSTALL PASSENGER AND NGINX
gem install passenger -v 4.0.45
export PATH="$PATH:/usr/local/bin"
passenger-install-nginx-module --auto --auto-download --languages python --prefix=/opt/nginx
useradd nginx
chown -R nginx: /opt/nginx
mkdir /var/log/nginx
chown -R nginx /var/log/nginx


# START MYSQL
service mariadb restart
chkconfig mariadb on

# ADD JENKINS_GIT_CICD DB AND USER TO MYSQL
cd /root
cat > user.sql <<EOF
create database if not exists cijtemplate;
grant all on ${MYSQL_CICD_DB}.* to ${MYSQL_CICD_USER}@localhost identified by '${MYSQL_CICD_PASS}';
EOF
mysql -uroot < user.sql

# LET JENKINS SSH AND SUDO
useradd jenkins
su - jenkins -c "mkdir -p ~/.ssh"
su - jenkins -c "echo '${JENKINS_KEY}' > ~/.ssh/authorized_keys"
su - jenkins -c "echo '${JENKINS_KEY}' > ~/.ssh/id_rsa.pub"
su - jenkins -c "echo '${JENKINS_PRIVATE_KEY}' > ~/.ssh/id_rsa"
su - jenkins -c "echo 'Host *' > ~/.ssh/config"
su - jenkins -c "echo 'StrictHostKeyChecking no' >> ~/.ssh/config"
chmod 600 /home/jenkins/.ssh/authorized_keys
chmod 600 /home/jenkins/.ssh/config
chmod 600 /home/jenkins/.ssh/id_rsa
chmod 644 /home/jenkins/.ssh/id_rsa.pub
chmod 700 /home/jenkins/.ssh
echo "jenkins ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/20-jenkins
# SET JENKINS GIT EMAIL AND NAME
su - jenkins -c "git config --global user.email 'jenkins@example.com'"
su - jenkins -c "git config --global user.name 'jenkins'"

# PUT THE SOURCE IN PLACE
mkdir -p /opt/cijtemplate
cd /opt/cijtemplate
NOW=$(date +"%Y%m%d%H%M%S")
mkdir $NOW
git clone git@github.com:godaddy/cijtemplate.git $NOW
ln -s $NOW current
cd current
./setupenv.sh

# CONFIGURE NGINX
# Now you can add nginx and relay to jenkins with HTTPS:
cat > /opt/nginx/conf/nginx.conf <<'EOF'
user nobody;
worker_processes 5;
pid /run/nginx.pid;

events {
    worker_connections  1024;
}
http {
    passenger_root /usr/local/share/gems/gems/passenger-4.0.45;
    passenger_ruby /usr/bin/ruby;
    passenger_python /bin/python3;
    passenger_debug_log_file /var/log/nginx/passenger_debug.log;
    passenger_log_level 0;

    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    
    server {
		listen 80 default;
		client_max_body_size 1G;
		server_name _;

		keepalive_timeout 10;

        location / {
			passenger_enabled on;
			root /opt/cijtemplate/current/cijtemplate/public;
		}
    }

    server {
		listen 443 ssl;
		client_max_body_size 1G;

		ssl on;
		ssl_certificate         /opt/nginx/ssl/server.crt;
		ssl_certificate_key     /opt/nginx/ssl/server.key;
		ssl_protocols           TLSv1 TLSv1.1 TLSv1.2;
		ssl_ciphers             HIGH:!aNULL:!MD5;
		
		server_name             _;
		
		access_log              /var/log/nginx/ssl_access.log;
		error_log               /var/log/nginx/ssl_error.log;

		location / {
			passenger_enabled on;
			root /opt/cijtemplate/current/cijtemplate/public;
		}

    }
}
EOF

mkdir /opt/nginx/ssl
cd /opt/nginx/ssl
# replace variables with your values:
openssl req -nodes -newkey rsa:2048 -keyout server.key -out server.csr -subj "/C=US/ST=Arizona/L=Phoenix/O=Global Security/OU=IT Department/CN=host.jenkins.tld"
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt

# SET THE APP MODE
cat > /etc/profile.d/app_mode.sh <<'EOF'
export APP_MODE="test"
EOF
chmod 755 /etc/profile.d/app_mode.sh

# PUT THE INIT.D FILE IN PLACE
cat > /lib/systemd/system/nginx.service <<'EOF'
[Unit]
Description=The nginx HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
EnvironmentFile=-/etc/profile.d/app_mode.sh
PIDFile=/run/nginx.pid
ExecStartPre=/opt/nginx/sbin/nginx -t
ExecStart=/opt/nginx/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload

# START NGINX
service nginx restart
chkconfig nginx on
