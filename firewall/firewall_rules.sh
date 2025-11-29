#!/bin/sh

# ------------------------------------------------------------------------------
# 1. Default Policy: DENY ALL
# ------------------------------------------------------------------------------
# We start by flushing (-F) all existing rules to ensure a clean slate.
iptables -F
iptables -X
# We set the default policy to DROP. If a packet doesn't explicitly match 
# an ALLOW rule below, it is silently destroyed.
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# ------------------------------------------------------------------------------
# 2. Loopback & State Tracking
# ------------------------------------------------------------------------------
# Allow internal processes to talk to themselves (required for Suricata/Syslog).
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# ------------------------------------------------------------------------------
# 3. State Management
# ------------------------------------------------------------------------------
# Established flows bypass IDS to save CPU, or scan if desired
# For strict security, we scan everything. For performance, we might only scan NEW.
# Here we scan NEW connections for SSH/SFTP, but allow Established to pass fast.
# Allow return traffic. If a connection was validly established (outgoing),
# allow the response packets back in.
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# ------------------------------------------------------------------------------
# 4. Management Access
# ------------------------------------------------------------------------------
# Allow you to SSH into the Firewall container itself from the Docker host.
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# ------------------------------------------------------------------------------
# 5. IDS Integration (The "Bump in the Wire")
# ------------------------------------------------------------------------------
# We define a variable for the target action.
# NFQUEUE: Sends the packet to userspace (Suricata) for inspection.
# --queue-num 0: Suricata will listen on queue 0.
# --queue-bypass: FAIL-OPEN mechanism. If Suricata crashes or is restarting,
# packets will NOT be dropped; they will bypass inspection to keep the network alive.
IDS_TARGET="NFQUEUE --queue-num 0 --queue-bypass"

# ------------------------------------------------------------------------------
# 6. Routing Rules (East-West Traffic)
# ------------------------------------------------------------------------------
# Only allow SSH (TCP 22) between subnets, AND force it through the IDS.
# Source: 172.20.0.0/16 (Any of our subnets)
# Dest:   172.20.0.0/16 (Any of our subnets)
iptables -A FORWARD -s 172.20.0.0/16 -d 172.20.0.0/16 -p tcp --dport 22 -j $IDS_TARGET

# ------------------------------------------------------------------------------
# 7. Telemetry Rules (East-West Traffic)
# ------------------------------------------------------------------------------
# Allow all subnets to send Syslog (9514) to the Cribl Worker (.20).
# We inspect this too, to ensure no one is exploiting the logging protocol.
iptables -A FORWARD -d 172.20.40.20 -p udp --dport 9514 -j $IDS_TARGET
iptables -A FORWARD -d 172.20.40.20 -p tcp --dport 9514 -j $IDS_TARGET

# ------------------------------------------------------------------------------
# 8. Internet Access (North-South Traffic)
# ------------------------------------------------------------------------------
# Allow ONLY the Cribl subnet (Source) to reach the Internet (! Dest internal).
# We allow port 4200 (Cribl Leader comms) and 443 (HTTPS).
iptables -A FORWARD -s 172.20.40.0/24 ! -d 172.20.0.0/16 -p tcp --dport 4200 -j $IDS_TARGET
iptables -A FORWARD -s 172.20.40.0/24 ! -d 172.20.0.0/16 -p tcp --dport 443 -j $IDS_TARGET

# ------------------------------------------------------------------------------
# 9. Internet Access for ClamAV updates
# ------------------------------------------------------------------------------
# Allow ClamAV (172.20.20.10) to query DNS (to find update mirrors)
iptables -A FORWARD -s 172.20.20.10 -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -d 172.20.20.10 -p udp --sport 53 -j ACCEPT

# Allow ClamAV to download updates (HTTP/HTTPS)
iptables -A FORWARD -s 172.20.20.10 -p tcp --dport 80 -j ACCEPT
iptables -A FORWARD -s 172.20.20.10 -p tcp --dport 443 -j ACCEPT

# Enable NAT for ClamAV so it can route back
iptables -t nat -A POSTROUTING -s 172.20.20.10 -j MASQUERADE


# ------------------------------------------------------------------------------
# 10. NAT (Masquerading)
# ------------------------------------------------------------------------------
# Required for internet access. When Cribl traffic leaves the Firewall container
# to go to the internet, replace the source IP with the Firewall's IP.
iptables -t nat -A POSTROUTING -s 172.20.40.0/24 ! -d 172.20.0.0/16 -j MASQUERADE
# Enable NAT for ClamAV so it can route back
# iptables -t nat -A POSTROUTING -s 172.20.20.10 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.20.20.10 ! -d 172.20.0.0/16 -j MASQUERADE

# ------------------------------------------------------------------------------
# 11. Logging Dropped Packets
# ------------------------------------------------------------------------------
# If a packet reaches this point, it hasn't matched any ACCEPT rule.
# Log it to the kernel log (dmesg) with a prefix, then it will hit default DROP.
iptables -A FORWARD -j LOG --log-prefix "FW-DROP: " --log-level 6
iptables -A INPUT -j LOG --log-prefix "FW-INPUT-DROP: " --log-level 6