# ------------------------------------------------------------------------------
# Falco Image Download
# ------------------------------------------------------------------------------
# Base image is usually Debian-slim or Ubuntu based.
# Debian opted for over distro-less so customised routing could be configured.
FROM falcosecurity/falco:latest-debian

# ------------------------------------------------------------------------------
# Installation packages
# ------------------------------------------------------------------------------
# rsyslog: To forward Falco's own internal application logs (not just alerts).
# iproute2: To change the default gateway so Falco traffic goes through the firewall.
# Changed to apt-get because the base image is Debian-like.
RUN apt-get update && apt-get install -y rsyslog iproute2 dos2unix && rm -rf /var/lib/apt/lists/*
# RUN apk update && apk add --no-cache rsyslog iproute2 && rm -rf /var/cache/apk/*

# ------------------------------------------------------------------------------
# Custom Entrypoint
# ------------------------------------------------------------------------------
# Copy a custom entrypoint to handle networking setup before starting Falco.
# This custom entrypoint will run the routing script, then launch the original Falco binary.
COPY entrypoint.sh /docker-entrypoint-custom.sh
# Make the custom entrypoint executable and convert line endings.
RUN chmod +x /docker-entrypoint-custom.sh && \
    dos2unix /docker-entrypoint-custom.sh

# Override the default Entrypoint to run our setup script first.
ENTRYPOINT ["/docker-entrypoint-custom.sh"]