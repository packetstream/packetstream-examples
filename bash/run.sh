#!/bin/bash
set -euo pipefail

# Check if PACKETSTREAM_PROXY_URLS environment variable is set
if [ -z "${PACKETSTREAM_PROXY_URLS:-}" ]; then
  echo "PACKETSTREAM_PROXY_URLS should be a comma separated list of proxy URLs" >&2
  exit 1
fi

# redact prints a proxy URL without its credentials
redact() {
  case "$1" in
    *@*)
      local rest="${1#*://}"
      echo "${1%%://*}://${rest%%:*}:xxxxx@${1##*@}"
      ;;
    *) echo "$1" ;;
  esac
}

# Define the endpoint
endpoint="https://ipv4.icanhazip.com"

# Loop through each proxy URL
IFS=',' read -ra proxies <<< "$PACKETSTREAM_PROXY_URLS"
for proxy in "${proxies[@]}"; do
  echo "Using proxy: $(redact "$proxy")"

  # Make the request through the proxy using curl. The proxy URL is read from
  # a config on stdin so the credentials never appear in the process list.
  if ! response=$(printf 'proxy = "%s"\n' "$proxy" | curl --config - --silent --show-error --fail --max-time 30 "$endpoint"); then
    echo "Failed to make request through proxy: $(redact "$proxy")" >&2
    exit 1
  fi

  # Print the response
  echo "Your IP is: $response"
done
