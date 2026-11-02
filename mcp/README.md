# PacketStream MCP server

PacketStream runs a remote [Model Context Protocol](https://modelcontextprotocol.io) server with two tools for AI agents:

- `packetstream_search` runs a Google search and returns the results as Markdown, with the JSON response as `structuredContent`;
- `packetstream_fetch` reads a public web page and returns it as Markdown.

Server URL for clients that send an API key:

```text
https://api.packetstream.io/v1/mcp
```

Use your client's Streamable HTTP transport, not SSE. The server is stateless: each POST gets one JSON response. Create a key on the [MCP page of the dashboard](https://app.packetstream.io/dashboard/mcp); it is the same key as the Search API and Fetch API. The examples below read it from `PACKETSTREAM_API_KEY` wherever the client supports that, so the key stays out of configuration files.

Each successful tool call costs $0.0025 from your prepaid balance. Listing tools is free, and a call without a valid key is not billed. The server tells agents to use these tools for every web search and page fetch, so check your client's tool-approval settings to control spend.

The full guide, including sign-in (OAuth) setup at `https://api.packetstream.io/v1/mcp/oauth` for clients such as Claude custom connectors, is at [packetstream.io/docs/mcp/clients](https://packetstream.io/docs/mcp/clients/).

## Claude Code

```bash
export PACKETSTREAM_API_KEY="YOUR_API_KEY"
claude mcp add --transport http --scope user packetstream https://api.packetstream.io/v1/mcp \
  --header 'Authorization: Bearer ${PACKETSTREAM_API_KEY}'
claude mcp list
```

- The single quotes store the variable name, not the key, in Claude Code's settings. Add the `export` line to your shell profile so the variable is set wherever Claude Code starts.
- Keep `--header` after the URL.
- `--scope user` makes the server available in every project.

To share the server with a team, commit a `.mcp.json` at the repository root. Each person sets `PACKETSTREAM_API_KEY`:

```json
{
  "mcpServers": {
    "packetstream": {
      "type": "http",
      "url": "https://api.packetstream.io/v1/mcp",
      "headers": { "Authorization": "Bearer ${PACKETSTREAM_API_KEY}" }
    }
  }
}
```

## Codex CLI

Codex sends the variable's value as the bearer token, so set it to the bare key:

```bash
export PACKETSTREAM_API_KEY="YOUR_API_KEY"
codex mcp add packetstream --url https://api.packetstream.io/v1/mcp \
  --bearer-token-env-var PACKETSTREAM_API_KEY
```

This writes the following to `~/.codex/config.toml`:

```toml
[mcp_servers.packetstream]
url = "https://api.packetstream.io/v1/mcp"
bearer_token_env_var = "PACKETSTREAM_API_KEY"
```

- While the variable is unset where Codex starts, Codex does not start the server, so the agent has no PacketStream tools and no error that explains why.
- With `approval_policy = "never"`, Codex refuses every tool call that needs approval. To let the tools run without asking, add `default_tools_approval_mode = "approve"` to the `[mcp_servers.packetstream]` table. Every successful call is billed.

## Cursor

Add this to `~/.cursor/mcp.json` for every project, or to `.cursor/mcp.json` for one project:

```json
{
  "mcpServers": {
    "packetstream": {
      "url": "https://api.packetstream.io/v1/mcp",
      "headers": { "Authorization": "Bearer ${env:PACKETSTREAM_API_KEY}" }
    }
  }
}
```

`${env:PACKETSTREAM_API_KEY}` reads the key from your environment. You can write `Bearer YOUR_API_KEY` instead in a file that you never commit.

## VS Code

Add this to `.vscode/mcp.json` in a workspace, or run **MCP: Open User Configuration** to add it for every workspace. VS Code asks for the key once and stores it securely:

```json
{
  "inputs": [
    {
      "type": "promptString",
      "id": "packetstream-api-key",
      "description": "PacketStream API key",
      "password": true
    }
  ],
  "servers": {
    "packetstream": {
      "type": "http",
      "url": "https://api.packetstream.io/v1/mcp",
      "headers": { "Authorization": "Bearer ${input:packetstream-api-key}" }
    }
  }
}
```

## Claude Desktop

Claude Desktop's configuration file starts local servers only, so it connects through the community [`mcp-remote`](https://github.com/geelen/mcp-remote) bridge, which needs Node.js. Open **Settings > Developer > Edit Config**, add this to `claude_desktop_config.json`, and restart Claude Desktop:

```json
{
  "mcpServers": {
    "packetstream": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "https://api.packetstream.io/v1/mcp",
        "--transport",
        "http-only",
        "--header",
        "Authorization:${PACKETSTREAM_AUTH_HEADER}"
      ],
      "env": { "PACKETSTREAM_AUTH_HEADER": "Bearer YOUR_API_KEY" }
    }
  }
}
```

- The key sits in the `env` block of this file, so keep the file private and out of version control.
- There is no space after `Authorization:` on purpose, because some systems split arguments at spaces. `mcp-remote` fills in the variable from `env`.
- The Code tab in Claude Desktop uses Claude Code's settings. Set it up as in [Claude Code](#claude-code).

## Other clients

Clients that support remote HTTP servers with custom headers usually take a configuration like this. Key names vary by client:

```json
{
  "mcpServers": {
    "packetstream": {
      "type": "http",
      "url": "https://api.packetstream.io/v1/mcp",
      "headers": { "Authorization": "Bearer YOUR_API_KEY" }
    }
  }
}
```

- **Cline** needs `"type": "streamableHttp"`. Without it, Cline uses SSE.
- **Gemini CLI** needs `httpUrl` instead of `url`. In Gemini CLI, `url` selects SSE.
- A client that runs only local (stdio) servers can use the `mcp-remote` bridge shown under [Claude Desktop](#claude-desktop).
- Browser-based clients cannot connect: the server sends no CORS headers. Never put your key in a web page.

## Check your key

A client that shows the server as connected has not checked your key: the server lists its tools without one and checks the key only on a tool call. This free call checks it:

```bash
curl -sS https://api.packetstream.io/v1/account \
  -H "Authorization: Bearer $PACKETSTREAM_API_KEY"
```

A tool call with a key problem returns an error result, not billed, with one of these codes:

- `missing_api_key`: no key was sent, or the variable that should hold it is empty where the client starts;
- `invalid_api_key`: the header does not hold a key of the form `ps_` and 64 lowercase hexadecimal characters, for example an unexpanded `${PACKETSTREAM_API_KEY}` or the `YOUR_API_KEY` placeholder;
- `unauthorized`: the key was revoked or replaced, or copied wrongly.

## Example code

[`python/`](python/) connects with the official MCP Python SDK, lists the tools, and calls `packetstream_search`.
