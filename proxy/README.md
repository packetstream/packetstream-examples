# Proxy examples

Every proxy example connects to `proxy.packetstream.io` with your PacketStream username and auth key. The full reference is in the [endpoint and authentication docs](https://packetstream.io/docs/endpoints-authentication/).

## Endpoints

| Protocol | Port | Use it when |
| --- | ---: | --- |
| HTTPS | 31111 | Default. The connection to the proxy is encrypted, including your credentials |
| HTTP | 31112 | The library cannot connect to an HTTPS proxy. Requests to HTTPS sites stay encrypted inside the tunnel, but your credentials reach the proxy unencrypted |
| SOCKS5 | 31113 | The client needs SOCKS5. Resolve hostnames through the proxy (`socks5h`) |

## Auth-key modifiers

Targeting and sessions are suffixes on the auth key, which is sent as the proxy password:

| Behaviour | Password |
| --- | --- |
| A new exit for each new connection | `AUTH_KEY` |
| A United States exit | `AUTH_KEY_country-US` |
| Keep one exit for a workflow | `AUTH_KEY_session-order42` |
| Both | `AUTH_KEY_country-US_session-order42` |

Use ISO two-letter country codes. Use session labels that contain no personal data. See [country targeting](https://packetstream.io/docs/country-targeting/) and [rotation and sticky sessions](https://packetstream.io/docs/rotation-sticky-sessions/).

## Environment variables

| Variable | Required | Meaning |
| --- | --- | --- |
| `PACKETSTREAM_USER` | yes | Your PacketStream username |
| `PACKETSTREAM_AUTH_KEY` | yes | Auth key from the [Proxy Access page](https://app.packetstream.io/dashboard/network_access) |
| `PACKETSTREAM_COUNTRY` | no | ISO two-letter code, such as `US` |
| `PACKETSTREAM_SESSION` | no | Sticky-session label, such as `order42` |
| `PACKETSTREAM_PROXY_PROTOCOL` | no | `https` (default), `http`, or `socks5` |
| `PACKETSTREAM_PROXY_HOST` | no | Defaults to `proxy.packetstream.io`; the smoke test points it at a local test proxy |

Each example makes two requests on separate connections. Without a session the two exit IPs usually differ; with a session they match.
