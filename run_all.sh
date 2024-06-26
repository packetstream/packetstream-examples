#!/bin/bash

# Ensure PACKETSTREAM_PROXY_URLS is set
if [ -z "$PACKETSTREAM_PROXY_URLS" ]; then
  echo "PACKETSTREAM_PROXY_URLS should be a comma separated list of proxy URLs"
  exit 1
fi

# Loop through each directory
for dir in */; do
  echo "Running $(basename "$dir")/run.sh..."

  # Change directory and execute run.sh
  (cd "$dir" && ./run.sh)
done
