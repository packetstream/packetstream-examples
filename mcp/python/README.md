# MCP server with Python

Connects to PacketStream's MCP server at `https://api.packetstream.io/v1/mcp` with the official [MCP Python SDK](https://github.com/modelcontextprotocol/python-sdk) over Streamable HTTP, lists the tools, and calls `packetstream_search`. It prints the tool names, then the search results as Markdown. A failed call comes back as a tool result with `isError` set; the example prints its `error.code` and `error.message` from `structuredContent` and exits non-zero.

| Variable | Required | Meaning |
| --- | --- | --- |
| `PACKETSTREAM_API_KEY` | yes | Your API key from the [MCP page of the dashboard](https://app.packetstream.io/dashboard/mcp), sent as `Authorization: Bearer <key>` |

The query comes from the command-line arguments and defaults to `residential proxy`. Listing tools is free and needs no valid key. Each successful `packetstream_search` call costs $0.0025; a call with a missing or wrong key is not billed. `packetstream_search` takes the [Search API parameters](https://packetstream.io/docs/search-api/parameters/) except `format`. See the [MCP reference](https://packetstream.io/docs/mcp/reference/) for both tools' arguments.

`requirements.txt` pins every package, generated from `requirements.in` with `uv pip compile` (command in its header).

## Run natively

Requires Python 3.11 or later.

```bash
read -r -s -p 'PacketStream API key: ' PACKETSTREAM_API_KEY; printf '\n'
export PACKETSTREAM_API_KEY
python -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
python main.py coffee grinders
```

## Run in Docker

```bash
docker build -t packetstream-mcp-python .
docker run --rm -e PACKETSTREAM_API_KEY packetstream-mcp-python coffee grinders
```
