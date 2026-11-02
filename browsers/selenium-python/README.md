# Selenium (Python) browser example

Launches headless Chrome with Selenium, opens `https://ipinfo.io/json` through PacketStream, and prints the exit IP.

Chrome takes the proxy address from `--proxy-server` but cannot take proxy credentials on the command line; it asks for them in an authentication challenge. The example answers that challenge through the Chrome DevTools Protocol `Fetch` domain, which Selenium exposes with `driver.start_devtools()`:

- it answers only challenges whose source is `Proxy`, so a website's own `401` challenge never receives the key;
- it answers once per request, so a wrong key fails at once instead of retrying.

Selenium's WebDriver BiDi handlers (`driver.network.add_auth_handler` and `add_authentication_handler`) look simpler, but in Chrome 156 they report a proxy challenge and a website's challenge identically, so they would send the key to any site that asks. They also stall a classic `driver.get()` while a challenge is pending. Third-party `selenium-wire` is unmaintained and is not needed.

Selenium cannot read the HTTP status of a page, so the example parses the page body as JSON and treats anything else as a failure.

Supported protocols: `https` (default) and `http`. SOCKS5 is not supported because Chrome has no SOCKS5 authentication ([Chromium proxy docs](https://chromium.googlesource.com/chromium/src/+/HEAD/net/docs/proxy.md#socksv5-proxy-scheme)). The DevTools approach works in Chrome and Edge, not Firefox. See [CONTRIBUTING.md](../../CONTRIBUTING.md) for the environment variables.

A browser reuses connections, so later pages in the same browser do not necessarily get a new exit. Start a new driver when you need one.

## Run natively

Requires Python 3.10 or later. Selenium Manager downloads a matching Chrome and ChromeDriver if they are missing.

```bash
python -m venv .venv && . .venv/bin/activate
pip install -r requirements.txt
export PACKETSTREAM_USER=your_username
export PACKETSTREAM_AUTH_KEY=your_auth_key
export PACKETSTREAM_COUNTRY=US          # optional
export PACKETSTREAM_SESSION=order42     # optional
export PACKETSTREAM_PROXY_PROTOCOL=http # optional: https or http
python main.py
```

## Run in Docker

The image uses Debian's Chromium and ChromeDriver and turns off the Chrome sandbox (`CHROME_NO_SANDBOX=1`), which needs privileges a default container does not have.

```bash
docker build -t packetstream-selenium-python .
docker run --rm -e PACKETSTREAM_USER -e PACKETSTREAM_AUTH_KEY \
  -e PACKETSTREAM_COUNTRY -e PACKETSTREAM_SESSION -e PACKETSTREAM_PROXY_PROTOCOL \
  packetstream-selenium-python
```
