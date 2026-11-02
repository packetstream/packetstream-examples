# Scrapy scraper example

Runs a one-request Scrapy spider that fetches `https://ipinfo.io/json` through PacketStream and prints the exit IP. The proxy is set per request with `meta["proxy"]`, and the credentials go in a separate `Proxy-Authorization` header, which Scrapy sends only on the `CONNECT` request to the proxy. `main.py` runs the spider with `CrawlerProcess`, so it can exit non-zero and print its own error without Scrapy's log, which would otherwise show request details.

Supported protocols: `http` only, which is the default here. Scrapy's default download handler raises `NotImplementedError("HTTPS proxies for HTTPS destinations are not supported")` for an `https://` proxy URL ([`http11.py`](https://github.com/scrapy/scrapy/blob/2.19.0/scrapy/core/downloader/handlers/http11.py)), and Scrapy has no SOCKS5 support. With the `http` port the connection to the proxy is unencrypted, but the site's TLS still runs end to end through the tunnel, so only the proxy credentials and the destination hostname are visible on the way to the proxy. See [CONTRIBUTING.md](../../CONTRIBUTING.md) for the environment variables.

Scrapy does not verify TLS certificates by default, so the example sets `DOWNLOAD_VERIFY_CERTIFICATES = True`. Keep it in your own projects.

Scrapy pools connections, so requests in the same crawl can share an exit. To keep using the proxy, set `meta["proxy"]` and the header on every request you create, including those yielded from callbacks.

## Run natively

Requires Python 3.10 or later.

```bash
python -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
export PACKETSTREAM_USER=your_username
export PACKETSTREAM_AUTH_KEY=your_auth_key
export PACKETSTREAM_COUNTRY=US      # optional
export PACKETSTREAM_SESSION=order42 # optional
python main.py
```

## Run in Docker

```bash
docker build -t packetstream-scrapy .
docker run --rm -e PACKETSTREAM_USER -e PACKETSTREAM_AUTH_KEY \
  -e PACKETSTREAM_COUNTRY -e PACKETSTREAM_SESSION \
  packetstream-scrapy
```
