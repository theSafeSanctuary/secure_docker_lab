# ------------------------------------------------------------------------------
# SFTP Server Image Download
# ------------------------------------------------------------------------------
# Alpine Linux, this keeps the image size small and consistent with the others.
FROM alpine:3.19

# ------------------------------------------------------------------------------
# Installation packages
# ------------------------------------------------------------------------------
# 1. openssh: The server software.
# 2. rsyslog: Essential for adhering to the "Send logs to Cribl" requirement.
# 3. iproute2: Contains the 'ip' command needed by the 'common_gateway.sh' script
#    to delete the default Docker gateway and point it to the Firewall.
RUN apk add --no-cache openssh rsyslog bash iproute2

# ------------------------------------------------------------------------------
# User and permissions setup
# ------------------------------------------------------------------------------
# 1. Create a group for SFTP users.
# 2. Create the user 'sftpuser' with NO shell access (/bin/false).
#    This prevents them from running commands if they somehow bypass SFTP restrictions.
RUN addgroup sftpusers && adduser -D -s /bin/false -G sftpusers sftpuser

# ------------------------------------------------------------------------------
# Directory and Chroot Setup
# ------------------------------------------------------------------------------
# CHROOT DIRECTORY PERMISSIONS (Critical Security Detail).
# Create the upload directory inside the chroot jail.
RUN mkdir -p /home/sftpuser/upload
# OpenSSH requires the ChrootDirectory to be owned by root and NOT writable by any other user.
# /home/sftpuser -> Owned by root (The Jail)
RUN chown root:root /home/sftpuser && chmod 755 /home/sftpuser
# /home/sftpuser/upload -> Owned by sftpuser (The writable drop box)
RUN chown sftpuser:sftpusers /home/sftpuser/upload && chmod 755 /home/sftpuser/upload
# Setup SSH Keys directory for sftpuser
RUN mkdir -p /home/sftpuser/.ssh

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
COPY entrypoint_sftp.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose SFTP port
EXPOSE 22

ENTRYPOINT ["/entrypoint.sh"]