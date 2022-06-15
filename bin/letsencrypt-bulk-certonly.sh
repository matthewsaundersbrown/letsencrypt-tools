#!/bin/bash

# must be root
if [ "$USER" != "root" ]; then
  exec sudo -u root $0 $@
fi

help()
{
  thisfilename=$(basename -- "$0")
  echo "Bulk installs Let's Encrypt certificates."
  echo ""
  echo "Usage: $thisfilename [OPTIONS]"
  echo ""
  echo "  -h    Print this help."
  echo
  echo "        Checks /srv/www/ for all virtualhosts and"
  echo "        runs letsencrypt-certonly.sh for any site"
  echo "        that doesn't already have a cert installed."
  exit
}


# check for help
if [ -n "$1" ]; then
  help
fi

readarray -t virtualhosts < <(ls -1 /srv/www/|grep -v ^html$)

for virtualhost in "${virtualhosts[@]}"; do

  # basic but good enough domain name regex validation
  if [[ $virtualhost =~ ^(([a-zA-Z0-9](-?[a-zA-Z0-9])*)\.)+[a-zA-Z]{2,}$ ]] ; then
    if [ ! -f /etc/letsencrypt/renewal/$virtualhost.conf ]; then
      echo "/usr/local/bin/letsencrypt-certonly.sh -d $virtualhost"
    fi
  fi

  # add code here to enable apache config

done
