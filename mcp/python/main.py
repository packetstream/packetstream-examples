"""List PacketStream's MCP tools and run one search with packetstream_search."""

import asyncio
import os
import sys

import httpx2
from mcp import Client
from mcp.client.streamable_http import streamable_http_client

MCP_URL = "https://api.packetstream.io/v1/mcp"


async def run(api_key, query):
    # Every tool call finishes or gives up within 25 seconds, so wait a little longer
    headers = {"Authorization": f"Bearer {api_key}"}
    async with (
        httpx2.AsyncClient(headers=headers, timeout=40) as http,
        Client(streamable_http_client(MCP_URL, http_client=http), read_timeout_seconds=40) as client,
    ):
        # Listing tools is free and works without a key
        tools = await client.list_tools()
        print("Tools:")
        for tool in tools.tools:
            print(f"  {tool.name}")

        # Each successful call is billed as one search
        print(f"\nCalling packetstream_search: query={query!r}\n")
        result = await client.call_tool("packetstream_search", {"query": query})

    if result.is_error:
        # A failed call, such as one with a bad key, is not billed. The JSON error is in structured_content.
        error = (result.structured_content or {}).get("error") or {}
        return f"Error: {error.get('code')}: {error.get('message')}"

    # The text content is the search results as Markdown. structured_content holds the JSON response.
    for block in result.content:
        if block.type == "text":
            print(block.text)
    return None


def main():
    api_key = os.environ.get("PACKETSTREAM_API_KEY")
    if not api_key:
        sys.exit("Set PACKETSTREAM_API_KEY")
    query = " ".join(sys.argv[1:]) or "residential proxy"
    try:
        failure = asyncio.run(run(api_key, query))
    except Exception as error:
        # The SDK runs the transport in a task group, so unwrap to the first underlying error
        while isinstance(error, ExceptionGroup):
            error = error.exceptions[0]
        sys.exit(f"MCP request failed: {type(error).__name__}: {error}")
    if failure:
        sys.exit(failure)


if __name__ == "__main__":
    main()
