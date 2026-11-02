# Search API with Python

Runs one Google search with `POST https://api.packetstream.io/v1/search` and prints `result_count` and each result's position, title, and URL. On failure it prints the API's `error.code` and `error.message` and exits non-zero. Uses [Requests](https://requests.readthedocs.io/).

See [CONTRIBUTING.md](../../CONTRIBUTING.md#api-example-contract) for the API example contract. Create a key on the [Search API page of the dashboard](https://app.packetstream.io/dashboard/search_api); the same key works for the Fetch API and the MCP server.

| Variable | Required | Meaning |
| --- | --- | --- |
| `PACKETSTREAM_API_KEY` | yes | Your API key, sent as `Authorization: Bearer <key>` |
| `PACKETSTREAM_SEARCH_TYPE` | no | Request type: `search` (default), `news`, `shopping`, `places`, `autocomplete`, `scholar`, or `ai_mode`. `ai_mode` returns an answer block instead of a result list, so the example prints only its `result_count` |
| `PACKETSTREAM_SEARCH_COUNTRY` | no | Two-letter country code to search from, such as `gb`. Defaults to `us`. `scholar` does not accept it |

The query comes from the command-line arguments and defaults to `residential proxy`. Each successful search costs $0.0025; errors, including a wrong key, are free. See the [Search API docs](https://packetstream.io/docs/search-api/) for every parameter.

## Run natively

Requires Python 3.10 or later.

```bash
read -r -s -p 'PacketStream API key: ' PACKETSTREAM_API_KEY; printf '\n'
export PACKETSTREAM_API_KEY
python -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
python main.py coffee grinders
PACKETSTREAM_SEARCH_TYPE=news PACKETSTREAM_SEARCH_COUNTRY=gb python main.py coffee grinders
```

## Run in Docker

```bash
docker build -t packetstream-search-api-python .
docker run --rm -e PACKETSTREAM_API_KEY -e PACKETSTREAM_SEARCH_TYPE -e PACKETSTREAM_SEARCH_COUNTRY packetstream-search-api-python coffee grinders
```
