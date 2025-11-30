#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

# ------------------------------------------------------------------------------
# SSH Key installation
# ------------------------------------------------------------------------------
echo "[ClamAV] Setting up SSH keys..."
# Make .ssh directory
mkdir -p /root/.ssh
# If a public key was successfully mounted into /tmp/id_rsa.pub, install it. Otherwise skip.
if [ -f /tmp/id_rsa.pub ]; then
	# ensure .ssh has correct perms
	chmod 700 /root/.ssh
    # write atomically and give strict perms/ownership
    install -m 600 -o root -g root /tmp/id_rsa.pub /root/.ssh/authorized_keys
    chown -R root:root /root/.ssh
    echo "[ClamAV] Successfully installed authorized_keys"
else
	echo "[ClamAV] No /tmp/id_rsa.pub found, skipping authorized_keys install"
fi

# ------------------------------------------------------------------------------
# Networking configuration
# ------------------------------------------------------------------------------
# Configure Networking - execute the common gateway script (mounted from host) to reroute traffic
# through the Firewall container (172.20.20.254) and point logs to Cribl (172.20.40.20).
# The arguments passed are specific to the AV subnet.
echo "[ClamAV] Configuring Network Routing..."
/usr/local/bin/gateway.sh 172.20.20.254 172.20.40.20

# ------------------------------------------------------------------------------
# Proxy setup and configuration
# ------------------------------------------------------------------------------
# Configure Freshclam Proxy - routes are updated through frirewall proxy (Tinyproxy).
# Proxy settings are appended to the freshclam configuration.
# Disable DNS checks in ClamAV to stop freshclam from validating DNS records as this requires UDP 53.
echo "[ClamAV] Configuring Freshclam Proxy..."
echo "HTTPProxyServer 172.20.20.254" >> /etc/clamav/freshclam.conf
echo "HTTPProxyPort 8888" >> /etc/clamav/freshclam.conf
echo "DNSDatabaseInfo no" >> /etc/clamav/freshclam.conf

# ------------------------------------------------------------------------------
# SSH configuration
# ------------------------------------------------------------------------------
# Start SSH Daemon.
# sshd forks to the background and returns control to the script immediately.
echo "[ClamAV] Starting SSH Daemon..."
/usr/sbin/sshd -D &

# ------------------------------------------------------------------------------
# ClamAV setup and configuration
# ------------------------------------------------------------------------------
# Start the ClamAV Daemon (clamd) in the background.
# The original image's entrypoint usually handles this, but its been overridden.
# Manually start the entrypoint provided by the base image To retain the original,
# behavior of the base image (like config generation).
# The official image creates a configuration file and starts freshclam/clamd.
echo "[ClamAV] Starting ClamAV Daemon..."
/init &

# ------------------------------------------------------------------------------
# ClamAV-SFTP File Watcher Service
# ------------------------------------------------------------------------------
# Start the File Watcher - This script waits for 'clamd' to be ready before it starts scanning.
# This is run in the background so it monitors files while the container is alive.
echo "[ClamAV] Starting Scan Watcher..."
/usr/local/bin/scan_watcher.sh &

# ------------------------------------------------------------------------------
# Container Keep-Alive
# ------------------------------------------------------------------------------
# Keep Container Alive - wait for the background processes. 
# If 'clamd' crashes, the container should exit.
wait -n