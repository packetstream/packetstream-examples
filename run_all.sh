#!/bin/bash

# Ensure PACKETSTREAM_PROXY_URLS is set
if [ -z "${PACKETSTREAM_PROXY_URLS:-}" ]; then
  echo "PACKETSTREAM_PROXY_URLS should be a comma separated list of proxy URLs" >&2
  exit 1
fi

failed=()

# Loop through each directory
for dir in */; do
  name=$(basename "$dir")
  echo "Running $name/run.sh..."

  # Change directory and execute run.sh
  if ! (cd "$dir" && ./run.sh); then
    failed+=("$name")
  fi
done

if [ ${#failed[@]} -gt 0 ]; then
  echo "Failed examples: ${failed[*]}" >&2
  exit 1
fi
