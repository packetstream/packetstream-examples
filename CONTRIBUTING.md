# Contributing

Contributions are welcome. Every example follows the same contract, so readers can switch languages without relearning the setup and one set of scripts can test them all.

> [!CAUTION]
> This repository is public. Never commit a username, auth key, API key, or `.env` file. If you expose a key, rotate it in the [dashboard](https://app.packetstream.io/dashboard/network_access) straight away.

## Layout

Each example lives in `<product>/<language-or-tool>/` and contains:

- `README.md`: what the example shows and the commands to run it natively and in Docker;
- the source, kept short enough to read in one sitting;
- a dependency manifest with a lockfile, or exact version pins where the ecosystem has no lockfile;
- a `Dockerfile` that runs the example as a non-root user. Docker is optional for readers, but the test scripts use it.

Add the example to [`examples.json`](examples.json) and to the table in the root [README](README.md).

## Proxy example contract

Proxy examples live under `proxy/`, `browsers/`, and `scrapers/`. They read these environment variables:

| Variable | Required | Meaning |
| --- | --- | --- |
| `PACKETSTREAM_USER` | yes | PacketStream username |
| `PACKETSTREAM_AUTH_KEY` | yes | Auth key from the [Proxy Access page](https://app.packetstream.io/dashboard/network_access) |
| `PACKETSTREAM_COUNTRY` | no | ISO two-letter code, such as `US`. Appended to the auth key as `_country-US` |
| `PACKETSTREAM_SESSION` | no | Sticky-session label. Appended as `_session-<label>`, after the country |
| `PACKETSTREAM_PROXY_PROTOCOL` | no | `https` (default, port 31111), `http` (31112), or `socks5` (31113) |
| `PACKETSTREAM_PROXY_HOST` | no | Defaults to `proxy.packetstream.io`. The smoke test points it at a local test proxy |

The example must:

1. Build the password as `AUTH_KEY[_country-CC][_session-LABEL]`.
2. Send credentials as proxy authentication. Prefer a separate username/password setting over a URL with embedded credentials when the library allows it.
3. Resolve the destination hostname through the proxy. For SOCKS5, use remote DNS (`socks5h` where the library distinguishes it).
4. Ignore `HTTP_PROXY`, `HTTPS_PROXY`, and similar variables so the request always uses PacketStream.
5. Proxy examples request `https://ipinfo.io/json` twice, each time on a new connection, and print the IP, country, city, and organisation. Without a session the two IPs usually differ; with a session they match. Browser and scraper examples may make a single request.
6. Print a first line naming the endpoint and modifiers, never the auth key. For example: `Proxy: https://proxy.packetstream.io:31111 country=US session=order42`.
7. Use a timeout of about 30 seconds per request.
8. Exit non-zero on any failure, with a short message that does not contain the auth key. Some libraries put the proxy URL in their error messages, so redact the key before printing.
9. Never disable TLS certificate verification.

If a library cannot use one of the protocols, say so in its README with a source, reject the value with a clear error, and list only the supported protocols in `examples.json`. If it cannot use `https`, default to `http` and explain in the README that the proxy credentials then reach the gateway unencrypted, although HTTPS destinations stay encrypted inside the tunnel.

## API example contract

Search API and Fetch API examples read `PACKETSTREAM_API_KEY`, send it as `Authorization: Bearer <key>`, use a client timeout of at least 35 seconds, and print the API's `error.code` and `error.message` on failure. They take their input as command-line arguments with a sensible default. Each successful call is billed, so the smoke test skips them; `tools/lint.sh` and the live test cover them.

## Testing

```bash
# Proxy examples: run against the local test proxy over each supported protocol
tools/smoke-proxy.sh proxy/python http socks5
```

The test proxy checks the username, the auth key, and its modifiers. It also confirms that the example printed an IP and never printed the key, including when the key is wrong. The HTTPS proxy port needs the real service and is covered by the live test, which maintainers run with `tools/live-test.sh`.

Run the language's usual formatter and linter. Go modules share the root [`.golangci.yml`](.golangci.yml).

## Pull requests

Feel free to include your [referral link](https://app.packetstream.io/dashboard/referrals) in your pull request if you would like to be credited for your contribution.
