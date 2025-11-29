FROM alpine:3.19

# DEPENDENCIES:
# 1. openssh: The server software.
# 2. rsyslog: Essential for adhering to the "Send logs to Cribl" requirement.
# 3. iproute2: Contains the 'ip' command needed by our 'common_gateway.sh' script
#    to delete the default Docker gateway and point it to the Firewall.
RUN apk add --no-cache openssh rsyslog bash iproute2

# Generate keys and set credentials
RUN ssh-keygen -A
RUN echo 'root:UserSSHPass123!' | chpasswd

# Copy the hardened config
COPY sshd_config /etc/ssh/sshd_config

WORKDIR /root
EXPOSE 22

# We do not define an ENTRYPOINT/CMD here because we override it in 
# docker-compose.yml to run the gateway script first.
CMD