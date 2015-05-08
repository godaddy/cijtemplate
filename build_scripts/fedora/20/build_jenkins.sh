#!/bin/bash -x
# Build script for the jenkins/sonar tester box

# START WITH A FRESH INSTALL OF Fedora-20

# Redirect stdout ( > ) into a named pipe ( >() ) running "tee"
exec > >(tee /root/buildlog.txt)
exec 2>&1

# VARIABLES
MYSQL_CICD_USER=jenkins
MYSQL_CICD_DB=cijtemplate
MYSQL_CICD_PASS=sOmeS3cureP8ss
MYSQL_SONAR_USER=sonar
MYSQL_SONAR_DB=sonar
MYSQL_SONAR_PASS=aStrongPass4Soner

# GET NEEDED SOFTWARE INSTALLED
yum -y update
yum -y install wget
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
wget -O /etc/yum.repos.d/sonar.repo http://downloads.sourceforge.net/project/sonar-pkg/rpm/sonar.repo
yum -y install git python3-pip gcc python3-devel jenkins java nginx mysql-server java-1.7.0-openjdk sonar pylint unzip


# CONFIGURE JENKINS WITH LOCALHOST ONLY AND START
sed -i 's/^JENKINS_LISTEN_ADDRESS=.*/JENKINS_LISTEN_ADDRESS="127.0.0.1"/' /etc/sysconfig/jenkins
sed -i 's&^JENKINS_ARGS=.*&JENKINS_ARGS="--prefix=/jenkins"&' /etc/sysconfig/jenkins
service jenkins restart
chkconfig jenkins on

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

# ADD SONAR DB AND USER TO MYSQL
cd /root
cat > sonar.sql <<EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_SONAR_DB} CHARACTER SET utf8 COLLATE utf8_general_ci;
GRANT ALL ON ${MYSQL_SONAR_DB}.* TO '${MYSQL_SONAR_USER}'@'localhost' IDENTIFIED BY '${MYSQL_SONAR_PASS}';
EOF
mysql -uroot < sonar.sql

# CONFIGURE SONAR FOR LOCALHOST ONLY
if [ ! -e /opt/sonar/conf/sonar.properties.orig ]; then
    cp /opt/sonar/conf/sonar.properties /opt/sonar/conf/sonar.properties.orig
fi
cat > /opt/sonar/conf/sonar.properties <<EOF
sonar.jdbc.url=jdbc:mysql://localhost:3306/${MYSQL_SONAR_DB}?useUnicode=true&characterEncoding=utf8&rewriteBatchedStatements=true&useConfigs=maxPerformance
sonar.jdbc.username=${MYSQL_SONAR_USER}
sonar.jdbc.password=${MYSQL_SONAR_PASS}
sonar.web.host=127.0.0.1
sonar.web.port=9000
sonar.web.context=/sonar
EOF
sed -i "s&/etc/init.d/&/etc/rc.d/init.d/&" /etc/rc.d/init.d/sonar
systemctl daemon-reload

# install the python-source plugin:
wget -O /opt/sonar/extensions/plugins/sonar-python-plugin-1.5.jar http://repository.codehaus.org/org/codehaus/sonar-plugins/python/sonar-python-plugin/1.5/sonar-python-plugin-1.5.jar

# START SONAR
chkconfig sonar on
service sonar start

# see http://docs.sonarqube.org/display/SONAR/Python+Plugin 
#   and http://docs.sonarqube.org/display/SONAR/Extending+Coding+Rules for extending rules

# install the sonar-runner app
wget -O /tmp/sonar-runner-dist-2.4.zip http://repo1.maven.org/maven2/org/codehaus/sonar/runner/sonar-runner-dist/2.4/sonar-runner-dist-2.4.zip
unzip -o /tmp/sonar-runner-dist-2.4.zip -d /opt
cp /opt/sonar-runner-2.4/conf/sonar-runner.properties /opt/sonar-runner-2.4/conf/sonar-runner.properties.orig
cat > /opt/sonar-runner-2.4/conf/sonar-runner.properties <<'EOF'
sonar.host.url=http://localhost:9000/sonar
sonar.jdbc.url=jdbc:mysql://localhost:3306/sonar?useUnicode=true&amp;characterEncoding=utf8
sonar.jdbc.username=sonar
sonar.jdbc.password=aStrongPass4Soner
EOF

# LET JENKINS SUDO
echo "jenkins ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/20-jenkins

# CREATE SSH KEY FOR JENKINS:
usermod -d /var/lib/jenkins -s /bin/bash jenkins
cat > /var/lib/jenkins/.bashrc <<'EOF'
# .bashrc
# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi
EOF
chown jenkins: /var/lib/jenkins/.bashrc
cat > /var/lib/jenkins/.bash_profile <<'EOF'
# .bash_profile
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
PATH=$PATH:$HOME/.local/bin:$HOME/bin
export PATH
EOF
chown jenkins: /var/lib/jenkins/.bash_profile
su - jenkins -c "mkdir -p ~/.ssh"
if [ ! -e /var/lib/jenkins/.ssh/id_rsa ]; then
    su - jenkins -c "ssh-keygen -t rsa -C 'your_email@example.com' -f ~/.ssh/id_rsa -N ''"
fi
su - jenkins -c "echo 'Host *' > ~/.ssh/config"
su - jenkins -c "echo 'StrictHostKeyChecking no' >> ~/.ssh/config"
su - jenkins -c "chmod 600 ~/.ssh/config"

# SET JENKINS GIT EMAIL AND NAME
su - jenkins -c "git config --global user.email 'jenkins@example.com'"
su - jenkins -c "git config --global user.name 'jenkins'"

# CONFIGURE NGINX
# Now you can add nginx and relay to jenkins with HTTPS:
cat > /etc/nginx/nginx.conf <<'EOF'
user nginx;
worker_processes 5;
pid /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
    gzip  on;

    upstream jenkins {
        server 127.0.0.1:8080 fail_timeout=0;
    }

    upstream sonar {
        server 127.0.0.1:9000 fail_timeout=0;
    }

    server {
      listen 80;
      return 301 https://$host$request_uri;
    }

    server {
      listen 443;
      server_name jenkins.koopman.me;

      ssl on;
      ssl_certificate /etc/nginx/ssl/server.crt;
      ssl_certificate_key /etc/nginx/ssl/server.key;

      location /jenkins {
        proxy_set_header        Host $host;
        proxy_set_header        X-Real-IP $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto $scheme;
        proxy_redirect          http:// https://;
        proxy_pass              http://jenkins;
      }

      location /sonar {
        proxy_set_header        Host $host;
        proxy_set_header        X-Real-IP $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header        X-Forwarded-Proto $scheme;
        proxy_redirect          http:// https://;
        proxy_pass              http://sonar;
      }
    }
}
EOF

mkdir /etc/nginx/ssl
cd /etc/nginx/ssl
# replace variables with your values:
openssl req -nodes -newkey rsa:2048 -keyout server.key -out server.csr -subj "/C=US/ST=Arizona/L=Phoenix/O=Global Security/OU=IT Department/CN=host.jenkins.tld"
openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
# do not start yet, services are vulnerable until after manual steps:
# service nginx restart
# chkconfig nginx on
