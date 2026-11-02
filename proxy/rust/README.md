# Rust proxy example

Makes two requests to `https://ipinfo.io/json` through PacketStream, each on a new connection, and prints the exit IP of each. Uses the blocking [reqwest](https://docs.rs/reqwest) client with rustls, so it needs no OpenSSL. The `socks` feature adds SOCKS5 support; the `socks5h://` scheme resolves the destination hostname through the proxy.

Supported protocols: `https` (default), `http`, `socks5`. See [CONTRIBUTING.md](../../CONTRIBUTING.md) for the environment variables.

## Run natively

Requires a current stable Rust toolchain (tested with 1.99).

```bash
export PACKETSTREAM_USER=your_username
export PACKETSTREAM_AUTH_KEY=your_auth_key
export PACKETSTREAM_COUNTRY=US          # optional
export PACKETSTREAM_SESSION=order42     # optional
export PACKETSTREAM_PROXY_PROTOCOL=http # optional: https, http, or socks5
cargo run --release
```

## Run in Docker

```bash
docker build -t packetstream-proxy-rust .
docker run --rm -e PACKETSTREAM_USER -e PACKETSTREAM_AUTH_KEY \
  -e PACKETSTREAM_COUNTRY -e PACKETSTREAM_SESSION -e PACKETSTREAM_PROXY_PROTOCOL \
  packetstream-proxy-rust
```
