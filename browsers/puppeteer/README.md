# Puppeteer browser example

Launches headless Chrome with Puppeteer, opens `https://ipinfo.io/json` through PacketStream, and prints the exit IP.

Chrome takes the proxy address from `--proxy-server` but has no option for proxy credentials; it asks for them in an authentication challenge. Puppeteer's `page.authenticate()` would answer that challenge, but it answers a website's own `401` challenge with the same credentials too. This example instead enables the DevTools `Fetch` domain on the page and answers only challenges whose source is `Proxy`, once per request, so a wrong key fails at once and websites never see the key.

Supported protocols: `https` (default) and `http`. SOCKS5 is not supported because Chrome has no SOCKS5 authentication ([Chromium proxy docs](https://chromium.googlesource.com/chromium/src/+/HEAD/net/docs/proxy.md#socksv5-proxy-scheme)). See [CONTRIBUTING.md](../../CONTRIBUTING.md) for the environment variables.

A browser reuses connections, so later pages in the same browser do not necessarily get a new exit. Launch a new browser when you need one. Pages opened later need their own `answerProxyChallenges(page)` call.

## Run natively

Requires Node.js 22.12 or later. Recent npm versions do not run Puppeteer's install script, so download Chrome explicitly:

```bash
npm ci
npx puppeteer browsers install chrome
export PACKETSTREAM_USER=your_username
export PACKETSTREAM_AUTH_KEY=your_auth_key
export PACKETSTREAM_COUNTRY=US          # optional
export PACKETSTREAM_SESSION=order42     # optional
export PACKETSTREAM_PROXY_PROTOCOL=http # optional: https or http
node index.js
```

## Run in Docker

The image uses Debian's Chromium and turns off the Chrome sandbox (`CHROME_NO_SANDBOX=1`), which needs privileges a default container does not have.

```bash
docker build -t packetstream-puppeteer .
docker run --rm -e PACKETSTREAM_USER -e PACKETSTREAM_AUTH_KEY \
  -e PACKETSTREAM_COUNTRY -e PACKETSTREAM_SESSION -e PACKETSTREAM_PROXY_PROTOCOL \
  packetstream-puppeteer
```
