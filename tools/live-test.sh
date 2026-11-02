#!/usr/bin/env bash
# Run examples against the real PacketStream service.
#
# Usage: tools/live-test.sh [example-dir...]   (default: every example)
#
# Needs PACKETSTREAM_USER and PACKETSTREAM_AUTH_KEY for proxy examples and
# PACKETSTREAM_API_KEY for API and MCP examples. Proxy traffic is billed, and
# each API example makes one to three billed calls.
#
# Each proxy example runs once per supported protocol, with a US country
# target and a sticky session. It must exit 0, report US for both requests,
# get the same exit IP twice, and never print a key. Residential exits can go
# offline mid-test, so a failed check is retried once with a new session.
#
# Exit IPs belong to PacketStream peers, so example output is not shown;
# failures print it with IP addresses masked.
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

if [ $# -gt 0 ]; then
  dirs=("${@%/}")
else
  mapfile -t dirs < <(jq -r '.[].dir' examples.json)
fi

failures=0

mask() {
  sed -E 's/([0-9]{1,3}\.){3}[0-9]{1,3}/x.x.x.x/g; s/[0-9a-fA-F]{1,4}(:[0-9a-fA-F]{0,4}){2,7}/x:x::x/g'
}

leaks_key() {
  local output=$1
  for name in PACKETSTREAM_AUTH_KEY PACKETSTREAM_API_KEY; do
    if [ -n "${!name:-}" ] && printf '%s' "$output" | grep -qF "${!name}"; then
      return 0
    fi
  done
  return 1
}

# report_failure <label> <attempt> <reason> <output>. The first attempt only
# warns; the retry counts as a failure.
report_failure() {
  if [ "$2" -lt 2 ]; then
    echo "RETRY $1: $3" >&2
    return
  fi
  echo "FAIL $1: $3" >&2
  printf '%s\n' "$4" | mask | sed 's/^/    /' >&2
  failures=$((failures + 1))
}

# check_proxy runs one proxy example once. It returns non-zero on failure and
# counts the failure only on the last attempt.
check_proxy() {
  local tag=$1 protocol=$2 label=$3 attempt=$4 output status ips countries
  # Pass values by name so keys stay out of the process list
  if output=$(
    PACKETSTREAM_PROXY_PROTOCOL=$protocol PACKETSTREAM_COUNTRY=US PACKETSTREAM_SESSION="live$RANDOM$RANDOM" \
      docker run --rm -e PACKETSTREAM_USER -e PACKETSTREAM_AUTH_KEY \
      -e PACKETSTREAM_PROXY_PROTOCOL -e PACKETSTREAM_COUNTRY -e PACKETSTREAM_SESSION \
      "$tag" 2>&1
  ); then
    status=0
  else
    status=$?
  fi

  if leaks_key "$output"; then
    report_failure "$label" "$attempt" "printed a key" "[output withheld]"
    return 1
  fi
  if [ "$status" -ne 0 ]; then
    report_failure "$label" "$attempt" "exited $status" "$output"
    return 1
  fi

  # "Request N: <ip>  <country>  ..." lines; browsers and scrapers may make one request
  mapfile -t ips < <(printf '%s\n' "$output" | sed -nE 's/^Request [0-9]+: ([^ ]+) +([A-Z]{2}).*/\1/p')
  mapfile -t countries < <(printf '%s\n' "$output" | sed -nE 's/^Request [0-9]+: ([^ ]+) +([A-Z]{2}).*/\2/p')
  if [ ${#ips[@]} -eq 0 ]; then
    report_failure "$label" "$attempt" "printed no 'Request N: <ip>  <country>' line" "$output"
  elif printf '%s\n' "${countries[@]}" | grep -qv '^US$'; then
    report_failure "$label" "$attempt" "country target ignored" "$output"
  elif [ "$(printf '%s\n' "${ips[@]}" | sort -u | wc -l)" -ne 1 ]; then
    report_failure "$label" "$attempt" "sticky session changed IP" "$output"
  else
    echo "PASS $label: ${#ips[@]} request(s), US, same exit IP"
    return 0
  fi
  return 1
}

for dir in "${dirs[@]}"; do
  kind=$(jq -r --arg dir "$dir" '.[] | select(.dir == $dir) | .kind' examples.json)
  if [ -z "$kind" ]; then
    echo "Unknown example: $dir" >&2
    exit 2
  fi

  tag="ps-live-${dir//\//-}"
  docker build -q -t "$tag" "$dir" >/dev/null

  if [ "$kind" = proxy ]; then
    : "${PACKETSTREAM_USER:?Set PACKETSTREAM_USER}" "${PACKETSTREAM_AUTH_KEY:?Set PACKETSTREAM_AUTH_KEY}"
    mapfile -t protocols < <(jq -r --arg dir "$dir" '.[] | select(.dir == $dir) | .protocols[]' examples.json)
    for protocol in "${protocols[@]}"; do
      label="$dir ($protocol)"
      for attempt in 1 2; do
        if check_proxy "$tag" "$protocol" "$label" "$attempt"; then
          break
        fi
      done
    done
  else
    : "${PACKETSTREAM_API_KEY:?Set PACKETSTREAM_API_KEY}"
    if output=$(docker run --rm -e PACKETSTREAM_API_KEY "$tag" 2>&1); then
      status=0
    else
      status=$?
    fi
    if leaks_key "$output"; then
      report_failure "$dir" 2 "printed a key" "[output withheld]"
    elif [ "$status" -ne 0 ]; then
      report_failure "$dir" 2 "exited $status" "$output"
    else
      echo "PASS $dir"
    fi
  fi
  docker rmi -f "$tag" >/dev/null
done

if [ "$failures" -gt 0 ]; then
  echo "$failures live check(s) failed" >&2
  exit 1
fi
