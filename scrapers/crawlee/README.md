# Crawlee scraper example

Runs a one-request Crawlee `HttpCrawler` that fetches `https://ipinfo.io/json` through PacketStream and prints the exit IP. The proxy is set with a `ProxyConfiguration`. Crawlee accepts proxy credentials only inside the proxy URL, so the example sets them with the `URL` username and password setters, which percent-encode them.

Supported protocols: `http` only, which is the default here. Crawlee's HTTP crawlers send requests with got-scraping, which rejects SOCKS5 with "Proxy URL protocol ... is not supported. Please use HTTP or HTTPS" ([source](https://github.com/apify/got-scraping/blob/master/src/hooks/proxy.ts)). It accepts an `https://` proxy URL, but then checks the proxy's `*.packetstream.io` certificate against the destination hostname, so every request fails with "Hostname/IP does not match certificate's altnames". With the `http` port the connection to the proxy is unencrypted, but the site's TLS still runs end to end through the tunnel, so only the proxy credentials and the destination hostname are visible on the way to the proxy. See [CONTRIBUTING.md](../../CONTRIBUTING.md) for the environment variables.

Settings worth keeping in your own crawlers:

- `ignoreSslErrors: false`. Crawlee's HTTP crawlers ignore TLS certificate errors by default, for the proxy and for the sites you crawl.
- Crawlee's log is turned off, because its messages can include proxy URLs and error details. The example prints its own messages with the key removed. If you turn the log back on, do not log `proxyInfo` or the proxy URL.
- `persistStorage: false` keeps the request queue in memory instead of writing `./storage`.

The example installs only `@crawlee/http`, which provides `HttpCrawler`. `CheerioCrawler` from `@crawlee/cheerio` or the `crawlee` package takes the same `proxyConfiguration` option.

## Run natively

Requires Node.js 22 or later.

```bash
npm ci
export PACKETSTREAM_USER=your_username
export PACKETSTREAM_AUTH_KEY=your_auth_key
export PACKETSTREAM_COUNTRY=US          # optional
export PACKETSTREAM_SESSION=order42     # optional
node index.js
```

## Run in Docker

```bash
docker build -t packetstream-crawlee .
docker run --rm -e PACKETSTREAM_USER -e PACKETSTREAM_AUTH_KEY \
  -e PACKETSTREAM_COUNTRY -e PACKETSTREAM_SESSION -e PACKETSTREAM_PROXY_PROTOCOL \
  packetstream-crawlee
```
