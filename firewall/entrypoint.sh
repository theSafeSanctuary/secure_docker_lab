#!/bin/bash
# Stop execution immediately if any command fails.
set -e

# ------------------------------------------------------------------------------
# SSH Key installation
# ------------------------------------------------------------------------------
echo "[Firewall] Setting up SSH Keys..."
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
    echo "[Firewall] Successfully installed authorized_keys"
else
	echo "[Firewall] No /tmp/id_rsa.pub found, skipping authorized_keys install"
fi

# ------------------------------------------------------------------------------
# Firewall Rules Application
# ------------------------------------------------------------------------------
echo "[Firewall] Applying Rules..."
# iptables rules applied BEFORE starting network services.
# This ensures a "Secure by Default" posture; no traffic passes until we explicitly allow it.
/usr/local/bin/firewall_rules.sh

# ------------------------------------------------------------------------------
# Syslog setup and configuration
# ------------------------------------------------------------------------------
echo "[Firewall] Starting Rsyslog..."
# We append a forwarding rule to the config file dynamically.
# '@@' forces TCP forwarding to Cribl, which is reliable but slightly heavier than UDP.
echo "*.* @@172.20.40.20:9514" >> /etc/rsyslog.conf
# Explicitly forward the 'local0' facility (used by Suricata in our yaml) to Cribl.
echo "local0.* @@172.20.40.20:9514" >> /etc/rsyslog.conf
# Start rsyslog as a background process so the script continues.
rsyslogd -n &

# ------------------------------------------------------------------------------
# Proxy setup and configuration
# ------------------------------------------------------------------------------
echo "[Firewall] Configuring Tinyproxy..."
# Allow access from internal subnets (172.20.0.0/16)
sed -i 's/^Allow 127\.0\.0\.1/Allow 172.20.0.0\/16/' /etc/tinyproxy/tinyproxy.conf
# Configure Tinyproxy to only accept local connections (Suricata) and ClamAV
# We overwrite the config to be strict.
cat > /etc/tinyproxy/tinyproxy.conf <<EOF
User root
Group root
Port 8888
Listen 0.0.0.0
Timeout 600

# Access Control
# Allow Localhost, specifically Suricata running on this container.
Allow 127.0.0.1
# Allow ClamAV to get signature updates.
Allow 172.20.20.10/24
# Allow Cribl Subnet to reach the Internet via the Proxy.
Allow 172.20.40.0/24

# Deny everything else
# (Tinyproxy denies by default if no Allow matches, but explicit is better)
EOF
# Start Tinyproxy
tinyproxy
# Define the proxy URL for firewall services (Localhost because Tinyproxy is on the same container)
export http_proxy="http://127.0.0.1:8888"
export https_proxy="http://127.0.0.1:8888"

# ------------------------------------------------------------------------------
# Suricata setup and configuration
# ------------------------------------------------------------------------------
echo "[Firewall] Updating Suricata Rules..."
# Update rules (using Emerging Threats Open by default)
# Fetches the latest signatures (ET Open) and compiles them into a single file.
# We use | so that if the update fails (e.g., no internet), the container doesn't crash.
# Run suricata-update if available, redirect output to a logfile and ignore
# non-zero exit status so the container continues.
suricata-update --no-reload

# Start the IDS engine.
echo "[Firewall] Starting Suricata IDS..."
# -q 0: Listen on NFQUEUE queue number 0 (matches our iptables rule).
# -D: Daemonize (run in background). 
/usr/bin/suricata -c /etc/suricata/suricata.yaml -q 0 &

# ------------------------------------------------------------------------------
# SSh Bastion setup and configuration
# ------------------------------------------------------------------------------
echo "[Firewall] Starting SSHD..."
# Start the SSH Bastion server.
# -D: Do NOT detach. This runs in the foreground and keeps the container alive.
# If SSHD dies, the container dies (which is good behavior for a Bastion).
exec /usr/sbin/sshd -D