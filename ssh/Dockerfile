# ------------------------------------------------------------------------------
# SSH Server Image Download
# ------------------------------------------------------------------------------
# Alpine Linux, this keeps the image size small and consistent with the others.
FROM alpine:3.19

# ------------------------------------------------------------------------------
# Installation packages
# ------------------------------------------------------------------------------
# 1. openssh: The server software.
# 2. rsyslog: Essential for adhering to the "Send logs to Cribl" requirement.
# 3. iproute2: Contains the 'ip' command needed by our 'common_gateway.sh' script
#    to delete the default Docker gateway and point it to the Firewall.
RUN apk add --no-cache openssh rsyslog bash iproute2

# ------------------------------------------------------------------------------
# SSH Configuration
# ------------------------------------------------------------------------------
# Copy the hardened config
RUN ssh-keygen -A
COPY sshd_config /etc/ssh/sshd_config

# ------------------------------------------------------------------------------
# Custom Entrypoint
# ------------------------------------------------------------------------------
# Copy a custom entrypoint to handle networking setup and set up the default gateway.
# The entrypoint is responsible for setting the default gateway to the Firewall.
COPY entrypoint_ssh.sh /entrypoint.sh
# Make the entrypoint executable
RUN chmod +x /entrypoint.sh

WORKDIR /root
EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]