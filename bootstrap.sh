#!/bin/bash
set -e

RELEASE=release/com/github/ukgovld/registry-core/0.0.2/registry-core-0.0.2.war

echo "** General updates"
yum update -y
yum install -y curl chkconfig

echo "** Installing nginx ..."
echo "**   download package ..."
yum install -y nginx.x86_64

if [ $(grep -c nginx /etc/logrotate.conf) -ne 0 ]
then
  echo "**   logrotate for nginx already configured"
else
  cat /vagrant/install/nginx.logrotate.conf >> /etc/logrotate.conf
  echo "**   logrotate for nginx configured"
fi
cp /vagrant/install/nginx.conf /etc/nginx/conf.d/localhost.conf

echo "**   starting service ..."
service nginx start
chkconfig nginx on

echo "** Installing java and tomcat ..."
yum install -y java-1.7.0-openjdk-demo.x86_64 tomcat7.noarch
alternatives --set java /usr/lib/jvm/jre-1.7.0-openjdk.x86_64/bin/java

if [ $(java -version 2>&1 | grep 1.7. -c) -ne 1 ]
then
  echo "**   ERROR: java version doesn't look right, try manual alternatives setting restart tomcat7"
  echo "**   java version is:"
  java -version
fi

echo "**    starting tomcat"
service tomcat7 start
chkconfig tomcat7 on

# Configure runtime areas
if ! blkid | grep /dev/xvdf; then
  # No visible attached volume but might not be formatted yet
  # This will just fail on a local vm
  mkfs -t ext4 /dev/xvdf || true
fi

if blkid | grep /dev/xvdf; then
  # We have an attached volume, mount it
  if ! mount | grep -q /dev/xvdf ; then
    # Not mounted yet but check if e.g. instance store is mounted in its place
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
    chown tomcat /mnt/opt/ldregistry
  fi
  if [ ! -d /mnt/varopt/ldregistry ]; then
    mkdir /mnt/varopt
    mkdir /mnt/varopt/ldregistry
    chown tomcat /mnt/varopt/ldregistry
  fi
  if [ ! -d /opt/ldregistry ]; then
    ln -s /mnt/opt/ldregistry /opt
  fi
  if [ ! -d /var/opt/nginx/cache ]; then
    mkdir -p /var/opt/nginx/cache
  fi
  
else
  # No attached volume, just just create empty ldregistry areas
  if [ ! -d "/opt/ldregistry" ]; then
    mkdir /opt/ldregistry
    chown tomcat /opt/ldregistry
  fi
  if [ ! -d "/var/opt/ldregistry" ]; then
    mkdir /var/opt/ldregistry
    chown tomcat /var/opt/ldregistry
  fi
fi
# If the static ldregistry area is not already set up then clone from the vagrant synced folder
if [ ! -d "/opt/ldregistry/conf" ]; then
  cp -R /vagrant/ldregistry/* /opt/ldregistry
  chown -R  tomcat /opt/ldregistry/*
fi

if [ ! -d "/var/log/ldregistry" ]; then
  mkdir /var/log/ldregistry
  chown tomcat /var/log/ldregistry
fi

# Set up configuration area /opt/ldregistry
echo "** Installing registry application"
rm -rf /var/lib/tomcat7/webapps/ROOT*
rm -rf /var/lib/tomcat7/webapps/registry*
curl -4s https://s3-eu-west-1.amazonaws.com/ukgovld/$RELEASE > /var/lib/tomcat7/webapps/registry.war
service tomcat7 restart

if [ $(grep -c -e 'tomcat.*/opt/ldregistry/proxy-conf.sh' /etc/sudoers) -ne 0 ]
then
  echo "** sudoers already configured"
else
  cat /vagrant/install/sudoers.conf >> /etc/sudoers
  echo "** added sudoers access to proxy configuration"
fi

cp /opt/ldregistry/ldrbackup.sh /etc/cron.daily
chmod +x /etc/cron.daily/ldrbackup.sh
