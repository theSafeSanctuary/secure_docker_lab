#!/bin/bash
set -e

# 1. Initialize Network Routing
# Falcosidekick is on the same subnet (Falco Net 30), so it uses the same gateway.
/usr/local/bin/gateway.sh 172.20.30.254 172.20.40.20

# 2. Start Falcosidekick
# It reads configuration from the environment variables defined in docker-compose.yml:
# - SYSLOG_HOST=172.20.40.20 (Cribl Worker)
# - SYSLOG_PORT=514
# - SYSLOG_PROTOCOL=tcp
echo "Starting Falcosidekick..."
exec /app/falcosidekick