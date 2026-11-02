# Python (httpx, asyncio)

Sends two requests to `https://ipinfo.io/json` at the same time through PacketStream with [httpx](https://www.python-httpx.org/)'s `AsyncClient`, and prints the exit IP, country, city, and organisation of each. Each request uses its own client, so it opens its own proxy connection.

Supports the `https`, `http`, and `socks5` proxy protocols. For SOCKS5 the example uses `socks5h`; httpx sends the destination hostname to the proxy with either scheme, so DNS is always resolved remotely.

## Run natively

Requires Python 3.10 or later.

```bash
pip install -r requirements.txt
export PACKETSTREAM_USER=your_username
export PACKETSTREAM_AUTH_KEY=your_auth_key
# Optional: PACKETSTREAM_COUNTRY=US, PACKETSTREAM_SESSION=order42, PACKETSTREAM_PROXY_PROTOCOL=socks5
python main.py
```

## Run with Docker

```bash
docker build -t packetstream-python-async .
docker run --rm -e PACKETSTREAM_USER -e PACKETSTREAM_AUTH_KEY packetstream-python-async
```

Add `-e PACKETSTREAM_COUNTRY`, `-e PACKETSTREAM_SESSION`, or `-e PACKETSTREAM_PROXY_PROTOCOL` to pass the optional settings.
