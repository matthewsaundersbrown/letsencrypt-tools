#!/bin/bash

# letsencrypt-sync-certs-to-etc-ssl.sh
#
# Takes all Let's Encrypt certs & keys and concats them in
# to pem files for use by apache, dovecot, exim, haproxy, etc.
#
# Install this script in to /etc/letsencrypt/renewal-hooks/post/
# to have it run automatically after attempting to obtain/renew certificates.
#
# Alternatively you can put the script in a different location and then
# run sync-certs-to-etc-ssl.sh manually after creating or renewing certs,
# or specificy the path to the script with the --post-hook cerbot command option
# to have it automatically run when attempting to obtain/renew certificates.

# make dir if it doesn't already exist
if [[ ! -e /etc/ssl/letsencrypt/ ]]; then
    install --owner=root --group=ssl-cert --mode=750 --directory /etc/ssl/letsencrypt
fi

# check that Let's Encrpyt archive dir exists before proceeding
if [ ! -d "/etc/letsencrypt/archive" ]; then
  exit
fi

# Get list of Let's Encrpyt certs
#   Check the "archive" dir instead of "live" as "live"
#   has a README file that we don't want in our array.
cd /etc/letsencrypt/archive/
lecerts=(*)
# get list of certs in the SSL dir
cd /etc/ssl/letsencrypt/
sslcerts=(*)

# First cycle thru /etc/ssl/letsencrypt/ and remove any pem
# files that don't have a cert in /etc/ssl/letsencrypt/
# (removes certs that have been deleted from letsencrypt).
for sslcert in "${!sslcerts[@]}"
do
  # set cert variable
  cert=${sslcerts[$sslcert]}
  # remove .pem from end of $cert
  cert=$(basename $cert .pem)
  if [[ ! " ${lecerts[@]} " =~ " $cert " ]]; then
    rm /etc/ssl/letsencrypt/${sslcerts[$sslcert]}
  fi
done

# add / update pem files in /etc/ssl/letsencrypt/
for lecert in "${!lecerts[@]}"
do
  # set cert variable
  cert=${lecerts[$lecert]}
  if [ -f "/etc/ssl/letsencrypt/$cert.pem" ]; then
    # /etc/ssl/letsencrypt/ pem file already exists
    # get modified times and only upate if newer
    LECERTTIME=`date +%s -r /etc/letsencrypt/live/$cert/fullchain.pem`
    SSLCERTTIME=`date +%s -r /etc/ssl/letsencrypt/$cert.pem`
    if [[ $LECERTTIME -gt $SSLCERTTIME ]]; then
      # make sure perms are correct, should be redundant
      chmod 640 /etc/ssl/letsencrypt/$cert.pem
      chown root:ssl-cert /etc/ssl/letsencrypt/$cert.pem
      # replace existing cert with new data
      cat /etc/letsencrypt/live/$cert/fullchain.pem > /etc/ssl/letsencrypt/$cert.pem
      cat /etc/letsencrypt/live/$cert/privkey.pem >> /etc/ssl/letsencrypt/$cert.pem
    fi
  else
    # /etc/ssl/letsencrypt/ pem file does not exists. First create
    # empty file with correct ownership and permissions. Thus the
    # copied cert is *never* world readable, not even for an instant.
    install --owner=root --group=ssl-cert --mode=640 /dev/null /etc/ssl/letsencrypt/$cert.pem
    cat /etc/letsencrypt/live/$cert/fullchain.pem > /etc/ssl/letsencrypt/$cert.pem
    cat /etc/letsencrypt/live/$cert/privkey.pem >> /etc/ssl/letsencrypt/$cert.pem
  fi
done
