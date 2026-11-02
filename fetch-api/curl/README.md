# Fetch API with curl

Reads one web page as Markdown with `POST https://api.packetstream.io/v1/fetch`. On failure it prints the API's `error.code` and `error.message` and exits non-zero. Uses bash, curl, and jq. The key reaches curl through a config on stdin, so it never appears in the process list.

See [CONTRIBUTING.md](../../CONTRIBUTING.md#api-example-contract) for the API example contract. Create a key on the [Search API page of the dashboard](https://app.packetstream.io/dashboard/search_api); the same key works for the Search API and the MCP server.

| Variable | Required | Meaning |
| --- | --- | --- |
| `PACKETSTREAM_API_KEY` | yes | Your API key, sent as `Authorization: Bearer <key>` |
| `PACKETSTREAM_FETCH_MAX_LENGTH` | no | Most characters per part, 1 to 500,000. Defaults to 50,000. Set a small value, such as `50`, to see pagination on a short page like the default |

The URL is the first command-line argument and defaults to `https://example.com`. The example prints the title, final URL, and HTTP status, then the Markdown. While `page.truncated` is `true` it sends the same request again with `start_index` set to `page.next_start_index`, up to 3 parts.

**Billing:** each fetch that returns content costs $0.0025, and each part read with `start_index` is a separate fetch, billed again (the page is downloaded again each time). Errors, including a wrong key, are free. Fetch does not run JavaScript. See the [Fetch API docs](https://packetstream.io/docs/fetch-api/).

## Run natively

Requires bash, curl, and jq.

```bash
read -r -s -p 'PacketStream API key: ' PACKETSTREAM_API_KEY; printf '\n'
export PACKETSTREAM_API_KEY
./run.sh https://go.dev/doc/effective_go
PACKETSTREAM_FETCH_MAX_LENGTH=50 ./run.sh
```

## Run in Docker

```bash
docker build -t packetstream-fetch-api-curl .
docker run --rm -e PACKETSTREAM_API_KEY -e PACKETSTREAM_FETCH_MAX_LENGTH packetstream-fetch-api-curl https://go.dev/doc/effective_go
```
