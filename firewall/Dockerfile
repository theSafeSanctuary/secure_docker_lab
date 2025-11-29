# We use Alpine Linux for its small attack surface (minimal packages installed by default).
FROM alpine:3.19

# INSTALLATION:
# 1. suricata: The IDS/IPS engine. Alpine's package typically includes NFQ support enabled.
# 2. libnetfilter_queue: Required library for Suricata to talk to the kernel's NFQUEUE.
# 3. iptables: The tool to configure the kernel firewall rules.
# 4. openssh: Provides the SSH server for the Bastion Host functionality.
# 5. rsyslog: The logging daemon to forward Suricata and Kernel logs to Cribl.
# 6. iproute2: Provides 'ip' command, useful for debugging routing tables.
# 7. python3/pip3: Required to run 'suricata-update' to fetch threat signatures.
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
    py3-pip

# Suricata-Update is a Python tool that manages rule downloads (Emerging Threats, etc.).
# We install it via pip to get the latest version compatible with the installed Suricata.
RUN pip3 install --upgrade suricata-update

# BASTION CONFIGURATION:
# We generate host keys for the SSH server so it can start.
# We set a root password for the Bastion login (In production, replace this with SSH Key COPY).
RUN ssh-keygen -A && \
    echo 'root:SecureAdmin123!' | chpasswd && \
    mkdir -p /root/.ssh

# Copy configuration artifacts
COPY sshd_config /etc/ssh/sshd_config
COPY firewall_rules.sh /usr/local/bin/firewall_rules.sh
COPY suricata.yaml /etc/suricata/suricata.yaml
COPY entrypoint.sh /entrypoint.sh

# Ensure scripts are executable
RUN chmod +x /usr/local/bin/firewall_rules.sh /entrypoint.sh

# The entrypoint script will orchestrate the startup of all 3 services (Firewall, IDS, SSH).
CMD ["/entrypoint.sh"]