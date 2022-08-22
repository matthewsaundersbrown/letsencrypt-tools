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
  echo "$thisfilename"
  echo "Create a Let's Encrypt certificate."
  echo ""
  echo "Usage: $thisfilename domain -d <domain> [-t] [-n] [-h]"
  echo ""
  echo "  -h          Print this help."
  echo "  -d <domain> Domain (hostname) to create certificate for."
  echo "  -t          Obtain certificates using a DNS TXT record (if you are using PowerDNS for DNS.)"
  echo "  -n          Dry Run - don't create cert, just echo command to run."
  exit
}

# set options
while getopts "hd:tn" opt; do
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
    t )
      dnstxt=true
      ;;
    n )
      dryrun=true
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

# set vars
command="certbot certonly"
if [[ -n $dnstxt ]]; then
  if [[ -f /usr/local/etc/pdns-credentials.ini ]]; then
    command="$command --authenticator certbot-dns-powerdns:dns-powerdns --certbot-dns-powerdns:dns-powerdns-credentials /usr/local/etc/pdns-credentials.ini --certbot-dns-powerdns:dns-powerdns-propagation-seconds 3"
  else
    echo "ERROR: /usr/local/etc/pdns-credentials.ini config file does not exist, can't use -t (DNS TXT authenticator)."
    exit 1
  fi
else
  command="$command --standalone"
fi

dnscheck=false
ips=(`ip -4  -o addr show | awk '{ print $4 }' | cut -d / -f 1`)

# check dns for domain
dns=`host -t A $domain|grep 'has address'|awk '{ print $4 }'`
if [[ " ${ips[@]} " =~ " ${dns} " ]]; then
  command="$command -d $domain"
  dnscheck=true
fi

# check dns for www subdomain
dns=`host -t A www.$domain|grep 'has address'|awk '{ print $4 }'`
if [[ " ${ips[@]} " =~ " ${dns} " ]]; then
  command="$command -d www.$domain"
  dnscheck=true
fi

# copy above www subdomain section and modify as desired to
# automatically check for and add additional subdomains to cert

# check if any of the dns lookups passed
if [[ "$dnscheck" = "false" ]]; then
  echo "All dns checks failed, can't create cert."
  exit 1
fi

# run (or display) command
if [[ "$dryrun" = "true" ]]; then
  echo "Run this command to create cert:"
  echo "$command"
else
  $command
fi
