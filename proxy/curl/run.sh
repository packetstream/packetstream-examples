#!/usr/bin/env bash
# Make two requests through PacketStream and print the exit IP of each.
set -euo pipefail

: "${PACKETSTREAM_USER:?Set PACKETSTREAM_USER}"
: "${PACKETSTREAM_AUTH_KEY:?Set PACKETSTREAM_AUTH_KEY}"
host="${PACKETSTREAM_PROXY_HOST:-proxy.packetstream.io}"
protocol="${PACKETSTREAM_PROXY_PROTOCOL:-https}"

case "$protocol" in
  https) proxy="https://$host:31111" ;;
  http) proxy="http://$host:31112" ;;
  # socks5h resolves the destination hostname through the proxy
  socks5) proxy="socks5h://$host:31113" ;;
  *)
    echo "Unsupported PACKETSTREAM_PROXY_PROTOCOL: $protocol (use https, http, or socks5)" >&2
    exit 1
    ;;
esac

# Targeting and sticky sessions are suffixes on the auth key
password="$PACKETSTREAM_AUTH_KEY"
description="Proxy: $proxy"
if [ -n "${PACKETSTREAM_COUNTRY:-}" ]; then
  password+="_country-$PACKETSTREAM_COUNTRY"
  description+=" country=$PACKETSTREAM_COUNTRY"
fi
if [ -n "${PACKETSTREAM_SESSION:-}" ]; then
  password+="_session-$PACKETSTREAM_SESSION"
  description+=" session=$PACKETSTREAM_SESSION"
fi
echo "$description"

for request in 1 2; do
  # Pass the credentials in a config read from stdin so they never appear in
  # the process list. --noproxy '' stops NO_PROXY from bypassing the proxy,
  # and each curl run opens a new connection.
  if ! body=$(
    printf 'proxy-user = "%s:%s"\n' "$PACKETSTREAM_USER" "$password" |
      curl --config - --proxy "$proxy" --noproxy '' \
        --silent --show-error --fail --max-time 30 \
        https://ipinfo.io/json
  ); then
    echo "Request $request failed" >&2
    exit 1
  fi

  printf 'Request %s: ' "$request"
  printf '%s' "$body" | jq -r '[.ip, .country, .city, .org] | join("  ")'
done
