#!/bin/bash
# Exit immediately if a command exits with a non-zero status.
set -e

# 1. Configure Networking
# We execute the common gateway script (mounted from host) to reroute traffic
# through the Firewall container (172.20.20.254) and point logs to Cribl (172.20.40.20).
# The arguments passed are specific to the AV subnet.
/usr/local/bin/gateway.sh 172.20.20.254 172.20.40.20

# 2. Start the ClamAV Daemon (clamd) in the background.
# The original image's entrypoint usually handles this, but since we overrode it,
# we manually start the entrypoint provided by the base image or just run clamd.
# The official image creates a configuration file and starts freshclam/clamd.
# We call the original entrypoint in the background to keep those behaviors.
/init &

# 3. Start the File Watcher
# We run this in the background so it monitors files while the container stays alive.
# This script waits for 'clamd' to be ready before it starts scanning.
/usr/local/bin/scan_watcher.sh &

# 4. Keep Container Alive
# We wait for the background processes. If 'clamd' crashes, the container should exit.
wait -n