#!/bin/bash

# must be root
if [ "$USER" != "root" ]; then
  exec sudo $0
fi

help()
{
  thisfilename=$(basename -- "$0")
  echo "$thisfilename"
  echo "Create a Let's Encrypt certificate."
  echo ""
  echo "Usage: $thisfilename domain [OPTIONS]"
  echo ""
  echo "  -h    Print this help."
  echo "  -n    Dry Run - don't create cert, just echo command to run."
  exit
}

# check for and set domain
if [ -n "$1" ]; then
  if [ $1 == "-h" ]; then
    help
  else
    domain=$1
    shift
    # basic but good enough domain name regex validation
    if [[ ! $domain =~ ^(([a-zA-Z](-?[a-zA-Z0-9])*)\.)+[a-zA-Z]{2,}$ ]] ; then
      echo "ERROR: Invalid domain name: $1"
      exit 1
    fi
  fi
else
  help
fi

# set any options that were passed
while getopts "hn" opt; do
  case "${opt}" in
    h )
      help
      exit;;
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

# set vars
command="certbot certonly --cert-name $domain"
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
