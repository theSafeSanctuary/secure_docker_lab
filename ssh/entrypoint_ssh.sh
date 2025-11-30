#!/bin/bash
# Stop execution immediately if any command fails.
set -e

# ------------------------------------------------------------------------------
# SSH Key installation
# ------------------------------------------------------------------------------
echo "[SSH Server] Setting up SSH Keys..."
# If a public key was mounted into /tmp/id_rsa.pub, install it. Otherwise skip.
# Make .ssh directory
mkdir -p /root/.ssh
# If a public key was successfully mounted into /tmp/id_rsa.pub, install it. Otherwise skip.
if [ -f /tmp/id_rsa.pub ]; then
	# ensure .ssh has correct perms
	chmod 700 /root/.ssh
    # write atomically and give strict perms/ownership
    install -m 600 -o root -g root /tmp/id_rsa.pub /root/.ssh/authorized_keys
    chown -R root:root /root/.ssh
    echo "[SSH Server] Successfully installed authorized_keys"
else
	echo "[SSH Server] No /tmp/id_rsa.pub found, skipping authorized_keys install"
fi

# ------------------------------------------------------------------------------
# Networking configuration
# ------------------------------------------------------------------------------
# Configure Networking - execute the common gateway script (mounted from host) to reroute traffic
# through the Firewall container (172.20.10.254) and point logs to Cribl (172.20.40.20).
chmod +x /usr/local/bin/gateway.sh
/usr/local/bin/gateway.sh 172.20.10.254 172.20.40.20

# Start SSH
exec /usr/sbin/sshd -D