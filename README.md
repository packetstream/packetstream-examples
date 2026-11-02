# PacketStream Examples

Runnable examples for [PacketStream](https://packetstream.io/): the residential proxy network, the Search API, the Fetch API, and the MCP server. Each example is a small, self-contained project with its own README, and a shared test script checks every one of them.

## Proxy examples

Each one makes two requests to `https://ipinfo.io/json` through PacketStream and prints the exit IP. Set a country or a sticky session to see targeting and sessions work.

| Example | Library | Proxy protocols |
| --- | --- | --- |
| [curl](proxy/curl) | curl | https, http, socks5 |
| [Python](proxy/python) | Requests | https, http, socks5 |
| [Python (async)](proxy/python-async) | HTTPX + asyncio | https, http, socks5 |
| [Node.js](proxy/nodejs) | Undici | https, http, socks5 |
| [Go](proxy/go) | net/http | https, http, socks5 |
| [Rust](proxy/rust) | reqwest | https, http, socks5 |
| [PHP](proxy/php) | cURL extension | https, http, socks5 |
| [C#](proxy/csharp) | HttpClient (.NET 10) | https, http, socks5 |
| [Ruby](proxy/ruby) | Net::HTTP | http, socks5 |
| [Java](proxy/java) | java.net.http.HttpClient | http |

## Browsers and scrapers

| Example | Proxy protocols |
| --- | --- |
| [Playwright (Node.js)](browsers/playwright-nodejs) | https, http |
| [Playwright (Python)](browsers/playwright-python) | https, http |
| [Puppeteer](browsers/puppeteer) | https, http |
| [Selenium (Python)](browsers/selenium-python) | https, http |
| [Crawlee](scrapers/crawlee) | http |
| [Scrapy](scrapers/scrapy) | http |

Chromium does not support authentication for SOCKS5 proxies, so the browser examples use the HTTPS or HTTP port. Each README explains any protocol a library cannot use.

## Search API, Fetch API and MCP

| Product | Examples |
| --- | --- |
| [Search API](https://packetstream.io/docs/search-api/): Google results as JSON | [curl](search-api/curl), [Python](search-api/python), [Node.js](search-api/nodejs), [Go](search-api/go) |
| [Fetch API](https://packetstream.io/docs/fetch-api/): a web page as Markdown | [curl](fetch-api/curl), [Python](fetch-api/python), [Node.js](fetch-api/nodejs), [Go](fetch-api/go) |
| [MCP server](https://packetstream.io/docs/mcp/): search and fetch tools for AI agents | [Client setup](mcp), [Python client](mcp/python) |

## Getting started

Sign up at [packetstream.io](https://app.packetstream.io/signup) and add funds.

- **Proxy examples** need your username and the auth key from the [Proxy Access page](https://app.packetstream.io/dashboard/network_access).
- **API and MCP examples** need an API key from the [Search API page](https://app.packetstream.io/dashboard/search_api).

Load them without writing them into your shell history:

```bash
read -r -p 'PacketStream username: ' PACKETSTREAM_USER
read -r -s -p 'PacketStream auth key: ' PACKETSTREAM_AUTH_KEY; printf '\n'
export PACKETSTREAM_USER PACKETSTREAM_AUTH_KEY

# Optional: target a country and keep one exit for a workflow
export PACKETSTREAM_COUNTRY=US PACKETSTREAM_SESSION=order42
```

Then follow the README in the example's directory. Each one can run natively or in Docker:

```bash
cd proxy/python
docker build -t packetstream-python .
docker run --rm -e PACKETSTREAM_USER -e PACKETSTREAM_AUTH_KEY -e PACKETSTREAM_COUNTRY -e PACKETSTREAM_SESSION packetstream-python
```

`-e NAME` without a value copies the variable from your shell, so the key never appears on the command line.

See [proxy/README.md](proxy/README.md) for the endpoints, the auth-key modifiers, and every environment variable the proxy examples read.

## Contributing

New examples and fixes are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for the contract each example follows and how to test it.

> [!CAUTION]
> This is a public repository. Never commit a username, auth key, API key, or `.env` file.

## Support

For help with PacketStream, see the [documentation](https://packetstream.io/docs/) or [contact support](https://packetstream.io/contact-us/). To report a security issue, see [SECURITY.md](SECURITY.md).

## License

MIT. Contributions are accepted under the same license. See [LICENSE](LICENSE).
