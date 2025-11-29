#!/bin/bash
set -e

# 1. Initialize Network Routing
# This directs traffic (alerts) through the Firewall Container (.254)
# and points Syslog to Cribl (.20)
/usr/local/bin/gateway.sh 172.20.30.254 172.20.40.20

# 2. Start Falco
# We pass arguments to output JSON logs (for Cribl parsing) and
# enable the HTTP output to talk to the local Falcosidekick container.
exec /usr/bin/falco \
    -o json_output=true \
    -o json_include_output_property=true \
    -o http_output.enabled=true \
    -o http_output.url=http://172.20.30.11:2801/