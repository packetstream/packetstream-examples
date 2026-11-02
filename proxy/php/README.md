# PHP (curl extension)

Sends two requests to `https://ipinfo.io/json` through PacketStream with PHP's built-in curl extension and prints the exit IP, country, city, and organisation of each. Each request uses a new curl handle, so it opens a new proxy connection. No Composer packages are needed.

Supports the `https` (`CURLPROXY_HTTPS`), `http` (`CURLPROXY_HTTP`), and `socks5` (`CURLPROXY_SOCKS5_HOSTNAME`, which resolves the destination hostname through the proxy) proxy protocols. The HTTPS proxy needs libcurl 7.52 or later built with HTTPS-proxy support.

## Run natively

Requires PHP 8.1 or later with the curl extension.

```bash
export PACKETSTREAM_USER=your_username
export PACKETSTREAM_AUTH_KEY=your_auth_key
# Optional: PACKETSTREAM_COUNTRY=US, PACKETSTREAM_SESSION=order42, PACKETSTREAM_PROXY_PROTOCOL=socks5
php main.php
```

## Run with Docker

```bash
docker build -t packetstream-php .
docker run --rm -e PACKETSTREAM_USER -e PACKETSTREAM_AUTH_KEY packetstream-php
```

Add `-e PACKETSTREAM_COUNTRY`, `-e PACKETSTREAM_SESSION`, or `-e PACKETSTREAM_PROXY_PROTOCOL` to pass the optional settings.
