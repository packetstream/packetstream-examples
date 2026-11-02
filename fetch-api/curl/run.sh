#!/usr/bin/env bash
# Read a web page as Markdown with the PacketStream Fetch API, following long pages.
set -euo pipefail

: "${PACKETSTREAM_API_KEY:?Set PACKETSTREAM_API_KEY}"
# The key goes into a curl config, so refuse characters that would break out of its quotes
case "$PACKETSTREAM_API_KEY" in
  *[\"\\$'\n']*)
    echo "PACKETSTREAM_API_KEY contains unexpected characters" >&2
    exit 1
    ;;
esac

url="${1:-https://example.com}"
# Optional: a small max_length splits even a short page into parts
max_length="${PACKETSTREAM_FETCH_MAX_LENGTH:-}"
if [ -n "$max_length" ] && ! [[ "$max_length" =~ ^[0-9]+$ ]]; then
  echo "PACKETSTREAM_FETCH_MAX_LENGTH must be a whole number" >&2
  exit 1
fi
# Each part is a separate fetch and is billed separately, so stop after a few
max_parts=3
echo "Fetch: $url"

start_index=0
for part in $(seq 1 "$max_parts"); do
  body=$(jq -n --arg url "$url" --arg max_length "$max_length" --argjson start_index "$start_index" \
    '{url: $url}
     + (if $max_length != "" then {max_length: ($max_length | tonumber)} else {} end)
     + (if $start_index > 0 then {start_index: $start_index} else {} end)')

  # Pass the Authorization header in a config read from stdin so the key never
  # appears in the process list. The server finishes or gives up within 25
  # seconds, so wait a little longer. The HTTP status goes on a last line of its own.
  if ! response=$(
    printf 'header = "Authorization: Bearer %s"\n' "$PACKETSTREAM_API_KEY" |
      curl --config - --silent --show-error --max-time 40 \
        --header 'Content-Type: application/json' --data "$body" \
        --write-out '\n%{http_code}' \
        https://api.packetstream.io/v1/fetch
  ); then
    echo "Request failed" >&2
    exit 1
  fi
  status="${response##*$'\n'}"
  payload="${response%$'\n'*}"

  if [ "$status" != 200 ]; then
    if message=$(printf '%s' "$payload" | jq -er '.error | "\(.code): \(.message)"' 2>/dev/null); then
      echo "Error $status: $message" >&2
    else
      echo "Error $status: unexpected response" >&2
    fi
    exit 1
  fi

  if [ "$part" = 1 ]; then
    printf '%s' "$payload" | jq -r '.page | "Title: \(.title)", "Final URL: \(.final_url)", "Status: \(.status_code)"'
  fi
  printf '%s' "$payload" | jq -r --arg part "$part" '.page |
    "\n--- Part \($part): characters \(.start_index) to \(.start_index + .returned_length) of \(.total_length) ---\n",
    .content'

  if [ "$(printf '%s' "$payload" | jq -r '.page.truncated')" != true ]; then
    exit 0
  fi
  # Send the same request again, starting where this part ended
  start_index=$(printf '%s' "$payload" | jq -r '.page.next_start_index')
done
echo
echo "Stopped after $max_parts parts. Continue with start_index=$start_index."
