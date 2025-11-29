FROM alpine:3.19

# Install dependencies (Same logic as SSH container: routing + logging + service)
RUN apk add --no-cache openssh rsyslog bash iproute2

# USER SETUP:
# 1. Create a group for SFTP users.
# 2. Create the user 'sftpuser' with NO shell access (/bin/false).
#    This prevents them from running commands if they somehow bypass SFTP restrictions.
RUN addgroup sftpusers && adduser -D -s /bin/false -G sftpusers sftpuser
RUN echo 'sftpuser:SecureSFTPPass!' | chpasswd

# CHROOT DIRECTORY PERMISSIONS (Critical Security Detail):
# OpenSSH requires the ChrootDirectory to be owned by root and NOT writable by any other user.
# /home/sftpuser -> Owned by root (The Jail)
# /home/sftpuser/upload -> Owned by sftpuser (The writable drop box)
RUN mkdir -p /home/sftpuser/upload
RUN chown root:root /home/sftpuser && chmod 755 /home/sftpuser
RUN chown sftpuser:sftpusers /home/sftpuser/upload && chmod 755 /home/sftpuser/upload

# Generate host keys for the server
RUN ssh-keygen -A

COPY sshd_config /etc/ssh/sshd_config
EXPOSE 22
CMD