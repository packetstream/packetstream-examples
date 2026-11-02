#!/usr/bin/env bash
# Run one Google search with the PacketStream Search API and print the results.
set -euo pipefail

: "${PACKETSTREAM_API_KEY:?Set PACKETSTREAM_API_KEY}"
# The key goes into a curl config, so refuse characters that would break out of its quotes
case "$PACKETSTREAM_API_KEY" in
  *[\"\\$'\n']*)
    echo "PACKETSTREAM_API_KEY contains unexpected characters" >&2
    exit 1
    ;;
esac

query="${*:-residential proxy}"
search_type="${PACKETSTREAM_SEARCH_TYPE:-}"
country="${PACKETSTREAM_SEARCH_COUNTRY:-}"
echo "Search: type=${search_type:-search} country=${country:-us} query=\"$query\""

# Only query is required. Leave out type and country to use the defaults: search and us.
body=$(jq -n --arg query "$query" --arg type "$search_type" --arg country "$country" \
  '{query: $query} + (if $type != "" then {type: $type} else {} end)
                   + (if $country != "" then {country: $country} else {} end)')

# Pass the Authorization header in a config read from stdin so the key never
# appears in the process list. The server finishes or gives up within 25
# seconds, so wait a little longer. The HTTP status goes on a last line of its own.
if ! response=$(
  printf 'header = "Authorization: Bearer %s"\n' "$PACKETSTREAM_API_KEY" |
    curl --config - --silent --show-error --max-time 40 \
      --header 'Content-Type: application/json' --data "$body" \
      --write-out '\n%{http_code}' \
      https://api.packetstream.io/v1/search
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

printf '%s' "$payload" | jq -r '
  "Results: \(.result_count)",
  # ai_mode returns its answer in .ai_mode and has no results list.
  # autocomplete items carry a suggestion instead of a title and URL.
  ((.results // [])[] | "\(.position). \(.title // .suggestion // "")  \(.url // "")" | sub(" +$"; ""))'
