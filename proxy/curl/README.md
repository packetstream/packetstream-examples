# curl proxy example

Makes two requests to `https://ipinfo.io/json` through PacketStream with curl, each on a new connection, and prints the exit IP of each. The credentials reach curl through a config read from standard input, so they never appear in the process list, and `--noproxy ''` stops `NO_PROXY` from bypassing the proxy.

Supported protocols: `https` (default), `http`, `socks5`. SOCKS5 uses `socks5h://`, so the proxy resolves the destination hostname. See [CONTRIBUTING.md](../../CONTRIBUTING.md) for the environment variables.

## Run natively

Requires bash, curl 7.52 or later (for HTTPS proxies), and jq.

```bash
export PACKETSTREAM_USER=your_username
export PACKETSTREAM_AUTH_KEY=your_auth_key
export PACKETSTREAM_COUNTRY=US          # optional
export PACKETSTREAM_SESSION=order42     # optional
export PACKETSTREAM_PROXY_PROTOCOL=http # optional: https, http, or socks5
./run.sh
```

## Run in Docker

```bash
docker build -t packetstream-proxy-curl .
docker run --rm -e PACKETSTREAM_USER -e PACKETSTREAM_AUTH_KEY \
  -e PACKETSTREAM_COUNTRY -e PACKETSTREAM_SESSION -e PACKETSTREAM_PROXY_PROTOCOL \
  packetstream-proxy-curl
```
