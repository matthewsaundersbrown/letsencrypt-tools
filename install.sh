#!/bin/bash
#
# letsencrypt-tools
# https://git.stack-source.com/msb/letsencrypt-tools
# Copyright (c) 2022 Matthew Saunders Brown <matthewsaundersbrown@gmail.com>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
#
# must be root
if [ "$USER" != "root" ]; then
  echo "You must be root to run this installer."
  exit
fi

# check for existing Let's Encrypt install
if [ -d "/etc/letsencrypt/" ]; then
  echo "WARNING: Let's Encrypt is already installed."
  echo "This installer will overwrite existing configurations."
  echo -e "You have five seconds to execute ctrl-c to cancel this install.\a"
  sleep 5
fi

apt-get update
apt-get -y install python3-certbot-apache

mkdir /etc/ssl/letsencrypt
chmod 750 /etc/ssl/letsencrypt
chgrp ssl-cert /etc/ssl/letsencrypt

# Let's Encrypt configurations
cp etc/letsencrypt/cli.ini /etc/letsencrypt/cli.ini
chmod 644 /etc/letsencrypt/cli.ini
chown root:root /etc/letsencrypt/cli.ini
mkdir -p /etc/letsencrypt/renewal-hooks/deploy/
cp etc/letsencrypt/renewal-hooks/deploy/cp-to-etc-ssl.sh /etc/letsencrypt/renewal-hooks/deploy/cp-to-etc-ssl.sh
chmod 750 /etc/letsencrypt/renewal-hooks/deploy/cp-to-etc-ssl.sh
chown root:root /etc/letsencrypt/renewal-hooks/deploy/cp-to-etc-ssl.sh

echo
domain=`hostname -d`
if [ -n "$domain" ]; then
  echo "email = hostmaster@$domain" >> /etc/letsencrypt/cli.ini
  echo "Let's Encrypt email set to hostmaster@$domain"
else
  echo "Server DNS domain name not set, Let's Encrypt email setting left unconfigured."
fi
echo

cp etc/apache2/conf-available/certbot.conf /etc/apache2/conf-available/certbot.conf
a2enmod --quiet proxy proxy_http
a2enconf --quiet certbot
systemctl restart apache2

# install Let's Encrypt user scripts
cp bin/letsencrypt-* /usr/local/bin
chmod 755 /usr/local/bin/letsencrypt-*
