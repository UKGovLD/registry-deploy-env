#!/bin/bash
set -e

RELEASE=snapshot/com/github/ukgovld/registry-core/0.0.2-SNAPSHOT/registry-core-0.0.2-20131204.093239-4.war

apt-get update -y
apt-get install -y curl chkconfig

# install and configure tomcat
echo "** Installing java and tomcat"
apt-get install -y tomcat7 language-pack-en
service tomcat7 stop

# tomcat7 on ubuntu seems hardwired to java-6 so have to dance around this
# installing java-7 first doesn't work and we end up with failures in tomcat startup
apt-get install -y openjdk-7-jdk 
update-alternatives --set java /usr/lib/jvm/java-7-openjdk-amd64/jre/bin/java
unlink /usr/lib/jvm/default-java
ln -s /usr/lib/jvm/java-1.7.0-openjdk-amd64 /usr/lib/jvm/default-java

if [[ $(java -version 2>&1 | grep 1.7. -c) -ne 1 ]]
then
  echo "**   ERROR: java version doesn't look right, try manual alternatives setting restart tomcat7"
  echo "**   java version is:"
  java -version
  exit 1
fi
service tomcat7 start
chkconfig tomcat7 on

# Configure runtime areas
if ! blkid | grep /dev/xvdf; then
  # No visible attached volume but might not be formatted yet
  # This will just fail on a local vm
  mkfs -t ext4 /dev/xvdf 
fi

if blkid | grep /dev/xvdf; then
  # We have an attached volume, mount it
  if ! mount | grep -q /dev/xvdf ; then
    # Not mounted yet but chec if e.g. instore store is mounted in its place
    if mount | grep -q /mnt ; then
      # Yes, in that case remove that mount
      umount /mnt
      mkdir /instance
      sed -i -e 's!/mnt!/instance!g' /etc/fstab
      mount /instance
    fi

    echo "/dev/xvdf /mnt ext4 rw 0 0" | tee -a /etc/fstab > /dev/null && mount /mnt  
  fi

  # If it's snapshot the ldregistry areas will exist, otherwise create them
  if [ ! -d /mnt/opt/ldregistry ]; then
    mkdir /mnt/opt
    mkdir /mnt/opt/ldregistry
    chown tomcat7 /mnt/opt/ldregistry
  fi
  if [ ! -d /mnt/varopt/ldregistry ]; then
    mkdir /mnt/varopt
    mkdir /mnt/varopt/ldregistry
    chown tomcat7 /mnt/varopt/ldregistry
  fi
  if [ ! -d /opt/ldregistry ]; then
    ln -s /mnt/opt/ldregistry /opt
  fi
  if [ ! -d /var/opt/ldregistry ]; then
    ln -s /mnt/varopt/ldregistry /var/opt
  fi
else
  # No attached volume, just just create empty ldregistry areas
  if [ ! -d "/opt/ldregistry" ]; then
    mkdir /opt/ldregistry
    chown tomcat7 /opt/ldregistry
  fi
  if [ ! -d "/var/opt/ldregistry" ]; then
    mkdir /var/opt/ldregistry
    chown tomcat7 /var/opt/ldregistry
  fi
fi
# If the static ldregistry area is not already set up then clone from the vagrant synced folder
if [ ! -d "/opt/ldregistry/conf" ]; then
  cp -R /vagrant/ldregistry/* /opt/ldregistry
  chown -R  tomcat7 /opt/ldregistry/*
fi

if [ ! -d "/var/log/ldregistry" ]; then
  mkdir /var/log/ldregistry
  chown tomcat7 /var/log/ldregistry
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
rm -rf /var/lib/tomcat7/webapps/ROOT*
rm -rf /var/lib/tomcat7/webapps/registry*
curl -4s https://s3-eu-west-1.amazonaws.com/ukgovld/$RELEASE > /var/lib/tomcat7/webapps/registry.war

if [ $(grep -c -e 'tomcat.*/opt/ldregistry/proxy-conf.sh' /etc/sudoers) -ne 0 ]
then
  echo "** sudoers already configured"
else
  cat /vagrant/install/sudoers.conf >> /etc/sudoers
  echo "** added sudoers access to proxy configuration"
fi