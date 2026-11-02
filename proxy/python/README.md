# Python (Requests) proxy example

Makes two requests to `https://ipinfo.io/json` through PacketStream with [Requests](https://requests.readthedocs.io/), each in a new session so it opens a new connection, and prints the exit IP of each. Each session sets `trust_env = False`, so `HTTP_PROXY`, `HTTPS_PROXY` and `NO_PROXY` cannot replace the PacketStream proxy.

Supported protocols: `https` (default), `http`, `socks5`. SOCKS5 needs the `requests[socks]` extra and uses `socks5h://`, so the proxy resolves the destination hostname. See [CONTRIBUTING.md](../../CONTRIBUTING.md) for the environment variables.

Requests reads proxy credentials from the proxy URL, so the example percent-encodes them into it and removes the auth key from any error message before printing it.

## Run natively

Requires Python 3.10 or later.

```bash
python -m pip install -r requirements.txt
export PACKETSTREAM_USER=your_username
export PACKETSTREAM_AUTH_KEY=your_auth_key
export PACKETSTREAM_COUNTRY=US          # optional
export PACKETSTREAM_SESSION=order42     # optional
export PACKETSTREAM_PROXY_PROTOCOL=http # optional: https, http, or socks5
python main.py
```

## Run in Docker

```bash
docker build -t packetstream-proxy-python .
docker run --rm -e PACKETSTREAM_USER -e PACKETSTREAM_AUTH_KEY \
  -e PACKETSTREAM_COUNTRY -e PACKETSTREAM_SESSION -e PACKETSTREAM_PROXY_PROTOCOL \
  packetstream-proxy-python
```
