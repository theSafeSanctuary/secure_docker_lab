#!/bin/sh

# ------------------------------------------------------------------------------
# Default Policy: DENY ALL
# ------------------------------------------------------------------------------
# We start by flushing (-F) all existing rules to ensure a clean slate.
iptables -F
iptables -X
# We set the default policy to DROP. If a packet doesn't explicitly match 
# an ALLOW rule below, it is silently destroyed.
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# ------------------------------------------------------------------------------
# Loopback & State Tracking
# ------------------------------------------------------------------------------
# Allow internal processes to talk to themselves (required for Suricata/Syslog).
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# ------------------------------------------------------------------------------
# State Management
# ------------------------------------------------------------------------------
# Established flows bypass IDS to save CPU, or scan if desired
# For strict security, we scan everything. For performance, we might only scan NEW.
# Here we scan NEW connections for SSH/SFTP, but allow Established to pass fast.
# Allow return traffic. If a connection was validly established (outgoing),
# allow the response packets back in.
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# ------------------------------------------------------------------------------
# IDS Integration (The "Bump in the Wire")
# ------------------------------------------------------------------------------
# We define a variable for the target action.
# NFQUEUE: Sends the packet to userspace (Suricata) for inspection.
# --queue-num 0: Suricata will listen on queue 0.
# --queue-bypass: FAIL-OPEN mechanism. If Suricata crashes or is restarting,
# packets will NOT be dropped; they will bypass inspection to keep the network alive.
IDS_TARGET="NFQUEUE --queue-num 0 --queue-bypass"

# ------------------------------------------------------------------------------
# Management Access
# ------------------------------------------------------------------------------
# Allow you IN to SSH into the Firewall container itself from the Docker host.
iptables -A INPUT -p tcp --dport 22 -j $IDS_TARGET
# Allow SSH OUT from the Firewall to Internal Containers (Jump Host functionality).
# Without this, you could log in to the firewall, but not jump to other nodes.
iptables -A OUTPUT -d 172.20.0.0/16 -p tcp --dport 22 -j $IDS_TARGET

# ------------------------------------------------------------------------------
# Inter-Subnet Routing Rules (East-West Traffic)
# ------------------------------------------------------------------------------
# Only allow SSH (TCP 22) between subnets, AND force it through the IDS.
# Source: 172.20.0.0/16 (Any of our subnets)
# Dest:   172.20.0.0/16 (Any of our subnets)
iptables -A FORWARD -s 172.20.0.0/16 -d 172.20.0.0/16 -p tcp --dport 22 -j $IDS_TARGET

# ------------------------------------------------------------------------------
# Telemetry Rules (East-West Traffic)
# ------------------------------------------------------------------------------
# FORWARD: Allow all subnets to send Syslog (9514) to the Cribl Worker (.20).
# We inspect this too, to ensure no one is exploiting the logging protocol.
iptables -A FORWARD -d 172.20.40.20 -p udp --dport 9514 -j $IDS_TARGET
iptables -A FORWARD -d 172.20.40.20 -p tcp --dport 9514 -j $IDS_TARGET

# OUTPUT: Allow the Firewall itself to send Syslog to Cribl
iptables -A OUTPUT -d 172.20.40.20 -p tcp --dport 9514 -j $IDS_TARGET

# ------------------------------------------------------------------------------
# Restricted Internet - Proxy Access (North-South Traffic)
# ------------------------------------------------------------------------------
# Allow ONLY the Cribl subnet (Source) to reach the Internet (! Dest internal).
# We allow port 4200 (Cribl Leader comms).
iptables -A FORWARD -s 172.20.40.0/24 ! -d 172.20.0.0/16 -p tcp --dport 4200 -j $IDS_TARGET
#iptables -A FORWARD -s 172.20.40.0/24 ! -d 172.20.0.0/16 -p tcp --dport 443 -j $IDS_TARGET

# INPUT: Allow ClamAV to reach Tinyproxy on the Firewall (Port 8888)
iptables -A INPUT -s 172.20.20.0/24 -p tcp --dport 8888 -j $IDS_TARGET
# INPUT: Allow Crible to reach Tinyproxy on the Firewall (Port 8888)
iptables -A INPUT -s 172.20.40.0/24 -p tcp --dport 8888 -j $IDS_TARGET

# OUTPUT: Allow Tinyproxy (running on Firewall) to reach the Internet
# We strictly limit this to DNS (53) and Web (80/443/4200) traffic.
iptables -A OUTPUT -p udp --dport 53 -j $IDS_TARGET
iptables -A OUTPUT -p tcp --dport 53 -j $IDS_TARGET
iptables -A OUTPUT -p tcp --dport 80 -j $IDS_TARGET
iptables -A OUTPUT -p tcp --dport 443 -j $IDS_TARGET
# iptables -A OUTPUT -p tcp --dport 4200 -j $IDS_TARGET

# ------------------------------------------------------------------------------
# NAT (Masquerading)
# ------------------------------------------------------------------------------
# 1. Masquerade Cribl traffic leaving the environment
iptables -t nat -A POSTROUTING -s 172.20.40.0/24 ! -d 172.20.0.0/16 -j MASQUERADE
# 2. Masquerade Firewall traffic (Tinyproxy) leaving eth0
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# ------------------------------------------------------------------------------
# Logging Dropped Packets
# ------------------------------------------------------------------------------
# If a packet reaches this point, it hasn't matched any ACCEPT rule.
# Log it to the kernel log (dmesg) with a prefix, then it will hit default DROP.
iptables -A FORWARD -j LOG --log-prefix "FW-DROP-FWD: " --log-level 6
iptables -A INPUT -j LOG --log-prefix "FW-DROP-IN: " --log-level 6
iptables -A OUTPUT -j LOG --log-prefix "FW-DROP-OUT: " --log-level 6