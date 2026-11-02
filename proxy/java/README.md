# Java

Makes two requests through PacketStream with the JDK's `java.net.http.HttpClient`, each on a new proxy connection, and prints the exit IP of each. No dependencies or build tool are needed.

## Protocols

This example supports only the HTTP proxy port (31112), so `PACKETSTREAM_PROXY_PROTOCOL` defaults to `http` and `https` or `socks5` exit with an error:

- **HTTPS proxy (31111):** `HttpClient` always opens a plain TCP connection to the proxy; `java.net.Proxy.Type` has only `DIRECT`, `HTTP`, and `SOCKS`, with no way to request TLS to the proxy. Traffic to `https://` sites is still encrypted end to end inside the `CONNECT` tunnel, but the `Proxy-Authorization` header, which carries your username and auth key, travels unencrypted to the PacketStream gateway. Use the HTTPS port from another language if that matters to you.
- **SOCKS5 (31113):** `HttpClient` uses only `HTTP` proxies and silently connects directly when a `ProxySelector` returns a SOCKS proxy ([`HttpRequestImpl.retrieveProxy`](https://github.com/openjdk/jdk25u/blob/master/src/java.net.http/share/classes/jdk/internal/net/http/HttpRequestImpl.java)).

## Proxy authentication

The example sends `Proxy-Authorization` with each request. `HttpClient` passes it to the proxy in the `CONNECT` request and strips it from the request sent through the tunnel.

By default the JDK removes Basic credentials from `CONNECT` requests, because `jdk.http.auth.tunneling.disabledSchemes=Basic` in `conf/net.properties`. The example clears it with `System.setProperty` at the start of `main`. The JDK reads the property once, when the HTTP client classes load, so in your own code set it before the first `HttpClient` is created, or pass `-Djdk.http.auth.tunneling.disabledSchemes=` on the command line.

## Run

Requires Java 21 or later (the Docker image uses Java 25).

```bash
export PACKETSTREAM_USER=your-username
export PACKETSTREAM_AUTH_KEY=your-auth-key
java Main.java
```

Optionally set `PACKETSTREAM_COUNTRY=US` or `PACKETSTREAM_SESSION=order42`.

## Docker

```bash
docker build -t packetstream-java .
docker run --rm -e PACKETSTREAM_USER -e PACKETSTREAM_AUTH_KEY packetstream-java
```
