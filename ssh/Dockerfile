FROM alpine:3.19

# DEPENDENCIES:
# 1. openssh: The server software.
# 2. rsyslog: Essential for adhering to the "Send logs to Cribl" requirement.
# 3. iproute2: Contains the 'ip' command needed by our 'common_gateway.sh' script
#    to delete the default Docker gateway and point it to the Firewall.
RUN apk add --no-cache openssh rsyslog bash iproute2

# Generate keys and set credentials
RUN ssh-keygen -A

# Copy the hardened config
COPY sshd_config /etc/ssh/sshd_config
COPY entrypoint_ssh.sh /entrypoint.sh

# Make the entrypoint executable
RUN chmod +x /entrypoint.sh

WORKDIR /root
EXPOSE 22

# The entrypoint is responsible for setting the default gateway to the Firewall.
# docker-compose.yml to run the gateway script first.
ENTRYPOINT ["/entrypoint.sh"]