#!/bin/bash
# Stop execution immediately if any command fails.
set -e

# 1. Setup SSH Keys (for CLI Management)
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

# 2. Setup SFTP User Keys (for file transfer)
echo "[Firewall] Setting up SSH Keys for users..."
# If a public key was mounted into /tmp/id_rsa.pub, install it. Otherwise skip.
if [ -f /tmp/id_rsa.pub ]; then
	cat /tmp/id_rsa.pub > /home/sftpuser/.ssh/authorized_keys
	# ensure .ssh has correct perms
	chmod 700 /home/sftpuser/.ssh
    chmod 600 /home/sftpuser/.ssh/authorized_keys
    chown -R sftpuser:sftpusers /home/sftpuser/.ssh
else
	echo "[Firewall] No /tmp/id_rsa.pub found, skipping authorized_keys install"
fi

# 3. Network & Start
chmod +x /usr/local/bin/gateway.sh
/usr/local/bin/gateway.sh 172.20.50.254 172.20.40.20
exec /usr/sbin/sshd -D