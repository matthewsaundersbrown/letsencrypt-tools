#!/bin/bash

# script is run once per domain after successful renewal with these vars available:
# $RENEWED_LINEAGE=/etc/letsencrypt/live/example.com
# $RENEWED_DOMAINS="example.com www.example.com"

# makes sure vars were passed and LE cert exits
if [ ! -n "$RENEWED_LINEAGE" ]; then
  exit 1
fi

if [ ! -f "$RENEWED_LINEAGE/fullchain.pem" ]; then
  exit 1
fi

if [ ! -d "/etc/ssl/letsencrypt" ]; then
  install --owner=root --group=ssl-cert --mode=750 --directory /etc/ssl/letsencrypt
fi

DOMAIN=`basename $RENEWED_LINEAGE`
PEM="/etc/ssl/letsencrypt/$DOMAIN.pem"

# If the file doesn't already exist first create empty file with correct ownership and
# permissions. Thus the copied cert is *never* world readable, not even for an instant.
if [ ! -f "$PEM" ]; then
  install --owner=root --group=ssl-cert --mode=640 /dev/null $PEM
fi

cat $RENEWED_LINEAGE/fullchain.pem > $PEM
cat $RENEWED_LINEAGE/privkey.pem >> $PEM
# set perms & ownership again just for good measure, should be redundant
chmod 640 $PEM
chown root:ssl-cert $PEM
