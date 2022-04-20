#!/bin/bash

# This script is run once after an attempt to renew one or more certs.

# Array of services to reload. A default list of typical services is listed.
# Note that service will only be restarted if it's installed and active,
# it's safe to have inactive/unneeded services in this array.
# Change this to suit your needs.
services=(apache2 dovecot exim4 haproxy postfix)

# Cycle through each service.
for service in "${services[@]}"; do
  # Check if service is active.
  if systemctl --quiet is-active $service; then
    # Reload service.
    systemctl reload $service
  fi
done
