#!/bin/bash
# USAGE:./common_gateway.sh <FIREWALL_IP> <CRIBL_IP>

GATEWAY_IP=$1
CRIBL_IP=$2

echo " [Gateway] Configuring Default Gateway to $GATEWAY_IP..."

# 1. Remove the default route provided by Docker (which points to the host).
# Without this, traffic would bypass your firewall container entirely.
ip route del default

# 2. Add the new default route pointing to the Firewall Container's IP 
# on the specific subnet this container is attached to.
ip route add default via "$GATEWAY_IP"

echo " [Gateway] Configuring Rsyslog..."
# Ensure basic rsyslog config exists if the image didn't provide one.
if [ ! -f /etc/rsyslog.conf ]; then 
    echo '$ModLoad imuxsock' > /etc/rsyslog.conf
fi

# 3. Configure Remote Logging
# '*.*' means ALL facilities and ALL severities.
# '@@' means use TCP (reliable). '@' would mean UDP (unreliable).
# This sends all local logs to the Cribl Worker.
echo "*.* @@$CRIBL_IP:514" >> /etc/rsyslog.conf

# Start the logging daemon in the background so it doesn't block the script.
#rsyslogd -n &
rsyslogd

echo " [Gateway] Network setup complete."