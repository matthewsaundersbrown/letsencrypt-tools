#!/bin/bash

# must be root
if [ "$USER" != "root" ]; then
  echo "You must be root to run this installer."
  exit
fi

apt-get -y install python3-certbot-apache

mkdir /etc/ssl/letsencrypt
chmod 750 /etc/ssl/letsencrypt
chgrp ssl-cert /etc/ssl/letsencrypt

# Let's Encrypt
cp etc/letsencrypt/cli.ini /etc/letsencrypt/cli.ini
chmod 644 /etc/letsencrypt/cli.ini
chown root:root /etc/letsencrypt/cli.ini
mkdir -p /etc/letsencrypt/renewal-hooks/deploy/
cp etc/letsencrypt/renewal-hooks/deploy/cp-to-etc-ssl.sh /etc/letsencrypt/renewal-hooks/deploy/cp-to-etc-ssl.sh
chmod 750 /etc/letsencrypt/renewal-hooks/deploy/cp-to-etc-ssl.sh
chown root:root /etc/letsencrypt/renewal-hooks/deploy/cp-to-etc-ssl.sh
mkdir -p /etc/letsencrypt/renewal-hooks/post/
cp etc/letsencrypt/renewal-hooks/post/sync-certs-to-etc-ssl.sh /etc/letsencrypt/renewal-hooks/post/sync-certs-to-etc-ssl.sh
chmod 750 /etc/letsencrypt/renewal-hooks/post/sync-certs-to-etc-ssl.sh
chown root:root /etc/letsencrypt/renewal-hooks/post/sync-certs-to-etc-ssl.sh

domain=`hostname -d`
if [ -n "$domain" ]; then
  echo "email = hostmaster@$domain" >> /etc/letsencrypt/cli.ini
  echo "Lets' Encrypt email set to hostmaster@$domain"
else
  echo "Server DNS domain name not set, Lets' Encrypt email setting left unconfigured."
fi

cp etc/apache2/conf-available/certbot.conf /etc/apache2/conf-available/certbot.conf
a2enmod --quiet proxy
a2enconf --quiet certbot
systemctl restart apache2

chmod 755 bin/*
cp bin/* /usr/local/bin/
