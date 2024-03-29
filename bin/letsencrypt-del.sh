#!/bin/bash
#
# letsencrypt-tools
# https://git.stack-source.com/msb/letsencrypt-tools
# Copyright (c) 2022 Matthew Saunders Brown <matthewsaundersbrown@gmail.com>
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)
#
# must be root
if [ "$USER" != "root" ]; then
  exec sudo -u root $0 $@
fi

help()
{
  thisfilename=$(basename -- "$0")
  echo "Delete an existing Let's Encrypt certificate."
  echo ""
  echo "Usage: $thisfilename cert-name(domain) [OPTIONS]"
  echo ""
  echo "  -h          Print this help."
  echo "  -d <domain> Domain (hostname) of the certificate to delete."
  echo "  -r          Revoke cert from Let's Encrypt before deleting files."
  exit
}

# set options
while getopts "hd:r" opt; do
  case "${opt}" in
    h )
      help
      exit;;
    d ) # domain name (hostname) to create cert for
      domain=${OPTARG,,}
      # basic but good enough domain name regex validation
      if [[ ! $domain =~ ^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)+[a-zA-Z]{2,}$ ]] ; then
        echo "ERROR: Invalid domain name: $1"
        exit 1
      fi
      ;;
    r ) # revoke
      revoke=true
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      exit;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      exit;;
  esac
done

# check for domain (hostname)
if [[ -z $domain ]]; then
  echo "domain (hostname) is required"
  exit
fi

# start by checking if the renewal config exits
if test -f "/etc/letsencrypt/renewal/$domain.conf"; then

  if [[ "$revoke" = "true" ]]; then
    certbot revoke --cert-path /etc/letsencrypt/live/$domain/fullchain.pem
  fi

  if test -f "/etc/letsencrypt/renewal/$domain.conf"; then
    rm "/etc/letsencrypt/renewal/$domain.conf"
  fi

  if test -d "/etc/letsencrypt/live/$domain"; then
    rm -r "/etc/letsencrypt/live/$domain"
  fi

  if test -d "/etc/letsencrypt/archive/$domain"; then
    rm -r "/etc/letsencrypt/archive/$domain"
  fi

  if test -f "/etc/ssl/letsencrypt/$domain.pem"; then
    rm "/etc/ssl/letsencrypt/$domain.pem";
  fi

  if test -h "/etc/ssl/letsencrypt/mail.$domain.pem"; then
    rm "/etc/ssl/letsencrypt/mail.$domain.pem";
  fi

else
  echo "Did not find cert for $domain."
fi
