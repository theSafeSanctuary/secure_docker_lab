# The Sidekick image is usually Alpine based.
FROM falcosecurity/falcosidekick:latest

# Switch to root to install packages (the default image might run as 'falco')
USER root

# Install routing and logging tools.
RUN apk add --no-cache rsyslog iproute2 bash

# Copy the wrapper script that sets the default gateway.
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# The entrypoint executes the gateway script, then starts Sidekick.
ENTRYPOINT ["/entrypoint.sh"]