#!/bin/bash
set -e

apt-get update -y
apt-get install -y curl chkconfig

# install and configure tomcat
echo "** Installing java and tomcat"
apt-get install -y openjdk-7-jdk tomcat7
update-alternatives --set java /usr/lib/jvm/java-7-openjdk-amd64/jre/bin/java
if [ $(java -version 2>&1 | grep 1.7. -c) -ne 1 ]
then
  echo "**   ERROR: java version doesn't look right, try manual alternatives setting restart tomcat7"
  echo "**   java version is:"
  java -version
  exit 1
fi
service tomcat7 start
chkconfig tomcat7 on

# Configure runtime areas
if [ ! -d "/var/opt/ldregistry" ]; then
  mkdir /var/opt/ldregistry
  chown tomcat7 /var/opt/ldregistry
  chgrp tomcat7 /var/opt/ldregistry
fi

if [ ! -d "/var/log/ldregistry" ]; then
  mkdir /var/log/ldregistry
  chown tomcat7 /var/log/ldregistry
  chgrp tomcat7 /var/log/ldregistry
fi

# install and configure nginx
echo "** Installing nginx"
apt-get install -y nginx
if [ $(grep -c nginx /etc/logrotate.conf) -ne 0 ]
then
  echo "**   logrotate for nginx already configured"
else
  cat /vagrant/install/nginx.logrotate.conf >> /etc/logrotate.conf
  echo "**   logrotate for nginx configured"
fi
cp /etc/nginx/sites-available/default  /etc/nginx/sites-available/original
cp /vagrant/install/nginx.conf /etc/nginx/sites-available/default

echo "**   starting nginx service ..."
service nginx restart
chkconfig nginx on

# Set up configuration area /opt/ldregistry
echo "** Installing registry application"
ln -s /vagrant/ldregistry /opt/ldregistry
rm -rf /var/lib/tomcat7/webapps/ROOT*
curl -4s https://s3-eu-west-1.amazonaws.com/ukgovld/release/com/github/ukgovld/registry-core/0.0.1/registry-core-0.0.1.war > /var/lib/tomcat7/webapps/ROOT.war

