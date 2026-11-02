"""Run one Google search with the PacketStream Search API and print the results."""

import os
import sys

import requests

API_URL = "https://api.packetstream.io/v1/search"


def main():
    api_key = os.environ.get("PACKETSTREAM_API_KEY")
    if not api_key:
        sys.exit("Set PACKETSTREAM_API_KEY")

    # Only query is required. Leave out type and country to use the defaults: search and us.
    body = {"query": " ".join(sys.argv[1:]) or "residential proxy"}
    if search_type := os.environ.get("PACKETSTREAM_SEARCH_TYPE"):
        body["type"] = search_type
    if country := os.environ.get("PACKETSTREAM_SEARCH_COUNTRY"):
        body["country"] = country
    print(f"Search: type={body.get('type', 'search')} country={body.get('country', 'us')} query={body['query']!r}")

    try:
        # The server finishes or gives up within 25 seconds, so wait a little longer
        response = requests.post(API_URL, headers={"Authorization": f"Bearer {api_key}"}, json=body, timeout=40)
    except requests.RequestException as error:
        sys.exit(f"Request failed: {error}")

    try:
        payload = response.json()
    except ValueError:
        payload = {}
    if not response.ok:
        error = payload.get("error") if isinstance(payload, dict) else None
        if isinstance(error, dict):
            sys.exit(f"Error {response.status_code}: {error.get('code')}: {error.get('message')}")
        sys.exit(f"Error {response.status_code}: unexpected response")

    print(f"Results: {payload.get('result_count')}")
    # ai_mode returns its answer in payload["ai_mode"] and has no results list
    for result in payload.get("results", []):
        # autocomplete items carry a suggestion instead of a title and URL
        title = result.get("title") or result.get("suggestion", "")
        print(f"{result.get('position')}. {title}  {result.get('url', '')}".rstrip())


if __name__ == "__main__":
    main()
