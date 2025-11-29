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

echo "[Firewall] Enabling IP Forwarding..."
# CRITICAL: This flips the kernel switch that allows this container to act as a router.
# Without this, packets arriving at eth1 (SSH Net) destined for eth2 (SFTP Net) would be dropped.


echo "[Firewall] Applying Rules..."
# We apply iptables rules BEFORE starting network services.
# This ensures a "Secure by Default" posture; no traffic passes until we explicitly allow it.
/usr/local/bin/firewall_rules.sh

echo "[Firewall] Updating Suricata Rules..."
# Update rules (using Emerging Threats Open by default)
# Fetches the latest signatures (ET Open) and compiles them into a single file.
# We use | so that if the update fails (e.g., no internet), the container doesn't crash.
# Avoid piping to a short-lived consumer (e.g. `| true`) because that closes the
# read end of the pipe and causes Python's logging to raise BrokenPipeError.
# Run suricata-update if available, redirect output to a logfile and ignore
# non-zero exit status so the container continues.
if command -v suricata-update >/dev/null 2>&1; then
	mkdir -p /var/log/suricata
	suricata-update --no-reload > /var/log/suricata/suricata-update.log 2>&1 || echo "[Firewall] suricata-update failed, continuing"
else
	echo "[Firewall] suricata-update not found, skipping"
fi

echo "[Firewall] Starting Rsyslog..."
# We append a forwarding rule to the config file dynamically.
# '@@' forces TCP forwarding to Cribl, which is reliable but slightly heavier than UDP.
echo "*.* @@172.20.40.20:514" >> /etc/rsyslog.conf
# Explicitly forward the 'local0' facility (used by Suricata in our yaml) to Cribl.
echo "local0.* @@172.20.40.20:514" >> /etc/rsyslog.conf
# Start rsyslog as a background process so the script continues.
rsyslogd -n &

echo "[Firewall] Starting Suricata IDS..."
# Start the IDS engine.
# -q 0: Listen on NFQUEUE queue number 0 (matches our iptables rule).
# -D: Daemonize (run in background). 
/usr/bin/suricata -c /etc/suricata/suricata.yaml -q 0 &

echo "[Firewall] Starting SSHD..."
# Start the SSH Bastion server.
# -D: Do NOT detach. This runs in the foreground and keeps the container alive.
# If SSHD dies, the container dies (which is good behavior for a Bastion).
#/usr/sbin/sshd -D
exec /usr/sbin/sshd -D