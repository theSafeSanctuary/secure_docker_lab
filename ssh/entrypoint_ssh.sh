#!/bin/bash
# Stop execution immediately if any command fails.
set -e

# 1. Setup SSH Keys
echo "[Firewall] Setting up SSH Keys..."
mkdir -p /root/.ssh
# If a public key was mounted into /tmp/id_rsa.pub, install it. Otherwise skip.
if [ -f /tmp/id_rsa.pub ]; then
	cat /tmp/id_rsa.pub > /root/.ssh/authorized_keys
	# ensure .ssh has correct perms
	chmod 700 /root/.ssh
	chmod 600 /root/.ssh/authorized_keys
	chown -R root:root /root/.ssh
else
	echo "[Firewall] No /tmp/id_rsa.pub found, skipping authorized_keys install"
fi

# Run gateway script (mounted in compose)
chmod +x /usr/local/bin/gateway.sh
/usr/local/bin/gateway.sh 172.20.10.254 172.20.40.20

# Start SSH
exec /usr/sbin/sshd -D