# Base image is usually Debian-slim or Ubuntu based.
FROM falcosecurity/falco:latest-debian

# We need to install:
# 1. rsyslog: To forward Falco's own internal application logs (not just alerts).
# 2. iproute2: To change the default gateway so Falco traffic goes through the firewall.
# We use apt-get because the base image is Debian-like.
RUN apt-get update && apt-get install -y rsyslog iproute2 dos2unix && rm -rf /var/lib/apt/lists/*
# RUN apk update && apk add --no-cache rsyslog iproute2 && rm -rf /var/cache/apk/*

# We copy a custom entrypoint wrapper.
# This wrapper will run our routing script, then launch the original Falco binary.
COPY entrypoint.sh /docker-entrypoint-custom.sh
# RUN chmod +x /docker-entrypoint-custom.sh
RUN chmod +x /docker-entrypoint-custom.sh && \
    dos2unix /docker-entrypoint-custom.sh

# Override the entrypoint to use our wrapper
ENTRYPOINT ["/docker-entrypoint-custom.sh"]