# Playwright (Python) browser example

Launches headless Chromium with Playwright, opens `https://ipinfo.io/json` through PacketStream, and prints the exit IP. The proxy is set with Playwright's `proxy: { server, username, password }` launch option (the sync API), and Playwright answers only the proxy's authentication challenge with those credentials, never a website's.

Supported protocols: `https` (default) and `http`. SOCKS5 is not supported: Chromium has no SOCKS5 authentication ([Chromium proxy docs](https://chromium.googlesource.com/chromium/src/+/HEAD/net/docs/proxy.md#socksv5-proxy-scheme)), and Playwright rejects it with "Browser does not support socks5 proxy authentication". See [CONTRIBUTING.md](../../CONTRIBUTING.md) for the environment variables.

A browser reuses connections, so later pages in the same browser do not necessarily get a new exit. Launch a new browser when you need one.

Do not run it with `DEBUG=pw:protocol` or `DEBUG=pw:*` set: the protocol log contains the proxy password.

## Run natively

Requires Python 3.10 or later.

```bash
python -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
playwright install chromium
export PACKETSTREAM_USER=your_username
export PACKETSTREAM_AUTH_KEY=your_auth_key
export PACKETSTREAM_COUNTRY=US          # optional
export PACKETSTREAM_SESSION=order42     # optional
export PACKETSTREAM_PROXY_PROTOCOL=http # optional: https or http
python main.py
```

## Run in Docker

The image is based on `mcr.microsoft.com/playwright/python`, whose tag matches the Playwright version in `requirements.txt`.

```bash
docker build -t packetstream-playwright-python .
docker run --rm -e PACKETSTREAM_USER -e PACKETSTREAM_AUTH_KEY \
  -e PACKETSTREAM_COUNTRY -e PACKETSTREAM_SESSION -e PACKETSTREAM_PROXY_PROTOCOL \
  packetstream-playwright-python
```
