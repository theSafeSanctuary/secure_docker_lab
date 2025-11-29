#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
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

# 2. Configure Networking
# We execute the common gateway script (mounted from host) to reroute traffic
# through the Firewall container (172.20.20.254) and point logs to Cribl (172.20.40.20).
# The arguments passed are specific to the AV subnet.
/usr/local/bin/gateway.sh 172.20.20.254 172.20.40.20

# 3. Start SSH Daemon
# We run this without flags. By default, sshd forks to the background 
# and returns control to the script immediately.
echo "Starting SSH Daemon..."
/usr/sbin/sshd -D &

# 4. Start the ClamAV Daemon (clamd) in the background.
# The original image's entrypoint usually handles this, but since we overrode it,
# we manually start the entrypoint provided by the base image or just run clamd.
# The official image creates a configuration file and starts freshclam/clamd.
# We call the original entrypoint in the background to keep those behaviors.
/init &

# 5. Start the File Watcher
# We run this in the background so it monitors files while the container stays alive.
# This script waits for 'clamd' to be ready before it starts scanning.
/usr/local/bin/scan_watcher.sh &

# 6. Keep Container Alive
# We wait for the background processes. If 'clamd' crashes, the container should exit.
wait -n