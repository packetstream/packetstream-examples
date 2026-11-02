#!/bin/bash
set -euo pipefail

# Ensure PACKETSTREAM_PROXY_URLS is set
if [ -z "${PACKETSTREAM_PROXY_URLS:-}" ]; then
    echo "PACKETSTREAM_PROXY_URLS should be a comma separated list of proxy URLs"
    exit 1
fi

# Build Docker image
docker build -t packetstream-example-node .

# Run Docker container, passing the variable by name so the credentials stay out of the process list
docker run --rm -e PACKETSTREAM_PROXY_URLS packetstream-example-node
