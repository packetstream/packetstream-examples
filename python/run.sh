#!/bin/bash
set -e

# Ensure PROXY_URLS is set
if [ -z "$PROXY_URLS" ]; then
    echo "PROXY_URLS should be a comma separated list of proxy URLs"
    exit 1
fi

# Build Docker image
docker build -t packetstream-example-python .

# Run Docker container with the necessary environment variable
docker run --rm -e PROXY_URLS="$PROXY_URLS" packetstream-example-python
