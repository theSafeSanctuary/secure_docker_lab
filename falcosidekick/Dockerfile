# ------------------------------------------------------------------------------
# Falco Sidekick Image Download
# ------------------------------------------------------------------------------
# The Sidekick image is usually Alpine based.
FROM falcosecurity/falcosidekick:latest

# ------------------------------------------------------------------------------
# Installation permissions
# ------------------------------------------------------------------------------
# Switch to root to install and configure system routing.
# The default image might drop to the 'falco' user, but root is needed 
# for 'apk add' and 'ip route' commands during startup.
USER root

# ------------------------------------------------------------------------------
# Installation packages
# ------------------------------------------------------------------------------
# Copy a custom entrypoint to handle networking setup before starting Falco Sidekick.
# This custom entrypoint will run the routing script, then launch the original Falco binary.
RUN apk add --no-cache rsyslog iproute2 bash

# ------------------------------------------------------------------------------
# Custom Entrypoint
# ------------------------------------------------------------------------------
# Copy the custom entrypoint script that sets the default gateway.
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# The entrypoint executes the gateway script, then starts Sidekick.
ENTRYPOINT ["/entrypoint.sh"]