#!/usr/bin/env bash
# Run a proxy example against the local test proxy.
#
# Usage: tools/smoke-proxy.sh <example-dir> <protocol>...
#
# https is skipped. For each other protocol (http or socks5) the example must:
#   - send the username and the auth key with its country and session
#     modifiers, which the test proxy checks;
#   - print an IP address and exit 0;
#   - never print the auth key;
#   - exit non-zero, still without printing the key, when the key is wrong.
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "usage: $0 <example-dir> <protocol>..." >&2
  exit 2
fi

root=$(cd "$(dirname "$0")/.." && pwd)
dir=${1%/}
shift

tag="ps-example-${dir//\//-}"
suffix="$$-$RANDOM"
network="ps-smoke-$suffix"
proxy="ps-testproxy-$suffix"
user="smoke-user"
key="canary$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')"
country="US"
session="smoke42"

cleanup() {
  docker rm -f "$proxy" >/dev/null 2>&1 || true
  docker network rm "$network" >/dev/null 2>&1 || true
  docker rmi -f "$tag" >/dev/null 2>&1 || true
}
trap cleanup EXIT

docker build -q -t ps-testproxy "$root/tools/testproxy" >/dev/null
docker build -q -t "$tag" "$root/$dir" >/dev/null
docker network create "$network" >/dev/null
docker run -d --name "$proxy" --network "$network" --network-alias testproxy \
  -e TESTPROXY_USER="$user" \
  -e TESTPROXY_PASSWORD="${key}_country-${country}_session-${session}" \
  ps-testproxy >/dev/null

run_example() {
  docker run --rm --network "$network" \
    -e PACKETSTREAM_USER="$user" \
    -e PACKETSTREAM_AUTH_KEY="$1" \
    -e PACKETSTREAM_COUNTRY="$country" \
    -e PACKETSTREAM_SESSION="$session" \
    -e PACKETSTREAM_PROXY_PROTOCOL="$2" \
    -e PACKETSTREAM_PROXY_HOST=testproxy \
    "$tag" 2>&1
}

failures=0
fail() {
  echo "FAIL $dir ($protocol): $1" >&2
  failures=$((failures + 1))
}

for protocol in "$@"; do
  if [ "$protocol" = https ]; then
    # The test proxy has no trusted certificate; tools/live-test.sh covers https.
    echo "  [https] skipped: covered by the live test"
    continue
  fi

  before=$(docker logs "$proxy" 2>&1 | grep -c "^.* ACCEPT $protocol" || true)

  if output=$(run_example "$key" "$protocol"); then
    status=0
  else
    status=$?
  fi
  printf '%s\n' "$output" | sed "s/^/  [$protocol] /"

  if [ "$status" -ne 0 ]; then
    fail "exited $status with valid credentials"
  fi
  if ! printf '%s\n' "$output" | grep -Eq '([0-9]{1,3}\.){3}[0-9]{1,3}|[0-9a-fA-F]*:[0-9a-fA-F:]+'; then
    fail "did not print an IP address"
  fi
  if printf '%s\n' "$output" | grep -qF "$key"; then
    fail "printed the auth key"
  fi
  after=$(docker logs "$proxy" 2>&1 | grep -c "^.* ACCEPT $protocol" || true)
  if [ "$after" -le "$before" ]; then
    fail "the test proxy accepted no $protocol connection"
  fi

  wrong_key="wrong${key}"
  if output=$(run_example "$wrong_key" "$protocol"); then
    fail "exited 0 with a wrong auth key"
  fi
  if printf '%s\n' "$output" | grep -qF "$wrong_key"; then
    fail "printed the auth key in an error"
  fi
done

if [ "$failures" -gt 0 ]; then
  echo "--- test proxy log" >&2
  docker logs "$proxy" >&2 2>&1 || true
  exit 1
fi

echo "PASS $dir ($*)"
