# Go proxy example

Makes two requests to `https://ipinfo.io/json` through PacketStream, each on a new connection, and prints the exit IP of each. Uses only the standard library: `net/http` supports `https://`, `http://` and `socks5h://` proxy URLs.

Supported protocols: `https` (default), `http`, `socks5`. See [CONTRIBUTING.md](../../CONTRIBUTING.md) for the environment variables.

## Run natively

Requires Go 1.27 or later.

```bash
export PACKETSTREAM_USER=your_username
export PACKETSTREAM_AUTH_KEY=your_auth_key
export PACKETSTREAM_COUNTRY=US          # optional
export PACKETSTREAM_SESSION=order42     # optional
export PACKETSTREAM_PROXY_PROTOCOL=http # optional: https, http, or socks5
go run .
```

## Run in Docker

```bash
docker build -t packetstream-proxy-go .
docker run --rm -e PACKETSTREAM_USER -e PACKETSTREAM_AUTH_KEY \
  -e PACKETSTREAM_COUNTRY -e PACKETSTREAM_SESSION -e PACKETSTREAM_PROXY_PROTOCOL \
  packetstream-proxy-go
```
