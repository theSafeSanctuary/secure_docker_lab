#!/bin/bash
# Stop execution immediately if any command fails.
set -e

# ------------------------------------------------------------------------------
# SSH Key installation
# ------------------------------------------------------------------------------
# Setup SSH Keys (for CLI Management)
echo "[SFTP] Setting up Management SSH Keys..."
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
    echo "[SFTP] Successfully installed authorized_keys for Admins"
else
	echo "[SFTP] No /tmp/id_rsa.pub found, skipping authorized_keys install for Admins"
fi

# Setup SFTP User Keys (for file transfer)
echo "[SFTP] Setting up SSH Keys for users..."
# If a public key was mounted into /tmp/id_rsa.pub, install it. Otherwise skip.
# Make .ssh directory
mkdir -p /root/.ssh
# If a public key was successfully mounted into /tmp/id_rsa.pub, install it. Otherwise skip.
if [ -f /tmp/id_rsa.pub ]; then
	# ensure .ssh has correct perms
	chmod 700 /home/sftpuser/.ssh
    # write atomically and give strict perms/ownership
    install -m 600 -o root -g root /tmp/id_rsa.pub /home/sftpuser/.ssh/authorized_keys
    chown -R sftpuser:sftpusers /home/sftpuser/.ssh
    echo "[SFTP] Successfully installed authorized_keys for Users"
else
	echo "[SFTP] No /tmp/id_rsa.pub found, skipping authorized_keys install for Users"
fi

# ------------------------------------------------------------------------------
# Networking configuration
# ------------------------------------------------------------------------------
# Configure Networking - execute the common gateway script (mounted from host) to reroute traffic
# through the Firewall container (172.20.50.254) and point logs to Cribl (172.20.40.20).
chmod +x /usr/local/bin/gateway.sh
/usr/local/bin/gateway.sh 172.20.50.254 172.20.40.20
exec /usr/sbin/sshd -D