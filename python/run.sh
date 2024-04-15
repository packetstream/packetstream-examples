#!/bin/bash
set -e

# Ensure PACKETSTREAM_PROXY_URLS is set
if [ -z "$PACKETSTREAM_PROXY_URLS" ]; then
    echo "PACKETSTREAM_PROXY_URLS should be a comma separated list of proxy URLs"
    exit 1
fi

# Build Docker image
docker build -t packetstream-example-python .

# Run Docker container with the necessary environment variable
docker run --rm -e PACKETSTREAM_PROXY_URLS="$PACKETSTREAM_PROXY_URLS" packetstream-example-python
