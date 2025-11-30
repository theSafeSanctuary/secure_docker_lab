# ------------------------------------------------------------------------------
# ClamAV Image Download
# ------------------------------------------------------------------------------
# We use the official ClamAV image using the 'latest' tag. 
# Alpine Linux, this keeps the image size small and consistent with the others.
FROM clamav/clamav:latest

# ------------------------------------------------------------------------------
# Installation permissions
# ------------------------------------------------------------------------------
# Switch to root user to install packages and configure system routing.
# The default image might drop to the 'clamav' user, but root is needed 
# for 'apk add' and 'ip route' commands during startup.
USER root

# ------------------------------------------------------------------------------
# Installation packages
# ------------------------------------------------------------------------------
# 1. inotify-tools: Provides 'inotifywait', which we use to watch the 
#    /scandata folder for new files.
# 2. rsyslog: Required to forward virus alerts to the Cribl Worker.
# 3. iproute2: Required for the 'common_gateway.sh' script to change 
#    the default gateway to our Firewall container.
# 4. bash: Required for our scripting logic.
RUN apk add --no-cache inotify-tools rsyslog iproute2 bash openssh
RUN ssh-keygen -A

# ------------------------------------------------------------------------------
# Make Quarantine Directory
# ------------------------------------------------------------------------------
# Create the quarantine directory where infected files will be moved.
# Ownership is changed to 'clamav' so the scanning process can write to it.
RUN mkdir /quarantine && chown clamav:clamav /quarantine

# ------------------------------------------------------------------------------
# Install ScanWatcher Script
# ------------------------------------------------------------------------------
# Copy the watcher script into the container.
COPY scan_watcher.sh /usr/local/bin/scan_watcher.sh
RUN chmod +x /usr/local/bin/scan_watcher.sh

# ------------------------------------------------------------------------------
# Custom Entrypoint
# ------------------------------------------------------------------------------
# Copy a custom entrypoint to handle networking setup before starting ClamAV.
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# We override the default Entrypoint to run our setup script first.
ENTRYPOINT ["/entrypoint.sh"]