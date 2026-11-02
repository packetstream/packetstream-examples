# Node.js proxy example

Makes two requests to `https://ipinfo.io/json` through PacketStream, each on a new connection, and prints the exit IP of each. Uses the built-in `fetch` with an [Undici](https://undici.nodejs.org/) dispatcher: `ProxyAgent` for `https` and `http`, and `Socks5ProxyAgent` for `socks5`, which resolves the destination hostname through the proxy.

Supported protocols: `https` (default), `http`, `socks5`. See [CONTRIBUTING.md](../../CONTRIBUTING.md) for the environment variables.

Undici marks `Socks5ProxyAgent` as experimental, so Node prints an `ExperimentalWarning` when you use `socks5`.

## Run natively

Requires Node.js 26 or later.

```bash
npm ci
export PACKETSTREAM_USER=your_username
export PACKETSTREAM_AUTH_KEY=your_auth_key
export PACKETSTREAM_COUNTRY=US          # optional
export PACKETSTREAM_SESSION=order42     # optional
export PACKETSTREAM_PROXY_PROTOCOL=http # optional: https, http, or socks5
node index.js
```

## Run in Docker

```bash
docker build -t packetstream-proxy-nodejs .
docker run --rm -e PACKETSTREAM_USER -e PACKETSTREAM_AUTH_KEY \
  -e PACKETSTREAM_COUNTRY -e PACKETSTREAM_SESSION -e PACKETSTREAM_PROXY_PROTOCOL \
  packetstream-proxy-nodejs
```
