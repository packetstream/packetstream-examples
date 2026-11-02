"""Read a web page as Markdown with the PacketStream Fetch API, following long pages."""

import os
import sys

import requests

API_URL = "https://api.packetstream.io/v1/fetch"
# Each part is a separate fetch and is billed separately, so stop after a few
MAX_PARTS = 3


def fetch_part(api_key, body):
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
    return payload["page"]


def main():
    api_key = os.environ.get("PACKETSTREAM_API_KEY")
    if not api_key:
        sys.exit("Set PACKETSTREAM_API_KEY")

    body = {"url": sys.argv[1] if len(sys.argv) > 1 else "https://example.com"}
    # Optional: a small max_length splits even a short page into parts
    if max_length := os.environ.get("PACKETSTREAM_FETCH_MAX_LENGTH"):
        if not max_length.isdigit():
            sys.exit("PACKETSTREAM_FETCH_MAX_LENGTH must be a whole number")
        body["max_length"] = int(max_length)
    print(f"Fetch: {body['url']}")

    for part in range(1, MAX_PARTS + 1):
        page = fetch_part(api_key, body)
        if part == 1:
            print(f"Title: {page['title']}")
            print(f"Final URL: {page['final_url']}")
            print(f"Status: {page['status_code']}")
        end = page["start_index"] + page["returned_length"]
        print(f"\n--- Part {part}: characters {page['start_index']} to {end} of {page['total_length']} ---\n")
        print(page["content"])

        if not page["truncated"]:
            return
        # Send the same request again, starting where this part ended
        body["start_index"] = page["next_start_index"]

    print(f"\nStopped after {MAX_PARTS} parts. Continue with start_index={body['start_index']}.")


if __name__ == "__main__":
    main()
