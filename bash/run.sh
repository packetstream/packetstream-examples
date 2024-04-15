#!/bin/bash
set -e

# Check if PACKETSTREAM_PROXY_URLS environment variable is set
if [ -z "$PACKETSTREAM_PROXY_URLS" ]; then
  echo "PACKETSTREAM_PROXY_URLS should be a comma separated list of proxy URLs"
  exit 1
fi

# Define the endpoint
endpoint="https://ipv4.icanhazip.com"

# Loop through each proxy URL
IFS=',' read -ra proxies <<< "$PACKETSTREAM_PROXY_URLS"
for proxy in "${proxies[@]}"; do
  echo "Using proxy: $proxy"

  # Make the request through the proxy using curl
  response=$(curl -x "$proxy" -s "$endpoint")

  # Check if curl encountered an error
  if [ $? -ne 0 ]; then
    echo "Failed to make request through proxy: $proxy"
    exit 1
  fi

  # Print the response
  echo "Your IP is: $response"
done
