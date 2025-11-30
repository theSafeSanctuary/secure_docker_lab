#!/bin/bash
set -e

# ------------------------------------------------------------------------------
# Networking configuration
# ------------------------------------------------------------------------------
# Configure Networking - execute the common gateway script (mounted from host) to reroute traffic
# through the Firewall container (172.20.30.254) and point logs to Cribl (172.20.40.20).
# Falcosidekick is on the same subnet (Falco Net 30), so it uses the same gateway.
echo "[Falco Sidekick] Configuring Network Routing..."
/usr/local/bin/gateway.sh 172.20.30.254 172.20.40.20

# ------------------------------------------------------------------------------
# Falco Sidekick configuration
# ------------------------------------------------------------------------------
# It reads configuration from the environment variables defined in docker-compose.yml:
# - SYSLOG_HOST=172.20.40.20 (Cribl Worker)
# - SYSLOG_PORT=514
# - SYSLOG_PROTOCOL=tcp
echo "[Falco Sidekick] Configuring Falco Sidekick..."
exec /app/falcosidekick