# ------------------------------------------------------------------------------
# Alpine Image Download
# ------------------------------------------------------------------------------
# Alpine Linux used as its a small attack surface (minimal packages installed by default).
FROM alpine:3.19

# ------------------------------------------------------------------------------
# Installation packages
# ------------------------------------------------------------------------------
# 1. suricata: The IDS/IPS engine. Alpine's package typically includes NFQ support enabled.
# 2. libnetfilter_queue: Required library for Suricata to talk to the kernel's NFQUEUE.
# 3. iptables: The tool to configure the kernel firewall rules.
# 4. openssh: Provides the SSH server for the Bastion Host functionality.
# 5. rsyslog: The logging daemon to forward Suricata and Kernel logs to Cribl.
# 6. iproute2: Provides 'ip' command, useful for debugging routing tables.
# 7. python3/pip3: Required to run 'suricata-update' to fetch threat signatures.
# 8. bash: Required for our scripting logic.
# 9. curl: Useful for testing connectivity from within the container.
# 10. openssl: Required for generating any SSL certificates if needed.
# 11. tinyproxy: A lightweight HTTP proxy for testing purposes.
RUN apk add --no-cache \
    suricata \
    libnetfilter_queue \
    iptables \
    openssh \
    rsyslog \
    bash \
    iproute2 \
    curl \
    python3 \
    py3-pip \
    openssl \
    tinyproxy

# Suricata-Update is a Python tool that manages rule downloads (Emerging Threats, etc.).
# Its installed to get the latest version compatible with the installed Suricata.
RUN apk add --no-cache --virtual .build-deps \
      build-base python3-dev libffi-dev openssl-dev cargo rust \
 && python3 -m venv /opt/suricata-venv \
 && /opt/suricata-venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel \
 && /opt/suricata-venv/bin/pip install --no-cache-dir suricata-update \
 && ln -s /opt/suricata-venv/bin/suricata-update /usr/local/bin/suricata-update \
 && apk del .build-deps

# ------------------------------------------------------------------------------
# Docker Configuration
# ------------------------------------------------------------------------------
# Copy configuration artifacts
RUN ssh-keygen -A
COPY sshd_config /etc/ssh/sshd_config
COPY firewall_rules.sh /usr/local/bin/firewall_rules.sh
COPY suricata.yaml /etc/suricata/suricata.yaml
COPY entrypoint.sh /entrypoint.sh

# ------------------------------------------------------------------------------
# Custom Entrypoint
# ------------------------------------------------------------------------------
# Ensure scripts are executable
RUN chmod +x /usr/local/bin/firewall_rules.sh /entrypoint.sh

# The entrypoint script will orchestrate the startup of all 3 services (Firewall, IDS, SSH).
ENTRYPOINT ["/entrypoint.sh"]