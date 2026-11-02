# Ruby (Net::HTTP)

Sends two requests to `https://ipinfo.io/json` through PacketStream with Ruby's standard `Net::HTTP` and prints the exit IP, country, city, and organisation of each. Each request opens and closes its own connection.

Supports the `http` and `socks5` proxy protocols. Net::HTTP has no SOCKS5 support, so the example uses the [socksify](https://github.com/astro/socksify-ruby) gem, which sends the destination hostname to the proxy (remote DNS, like `socks5h`).

**The `https` proxy protocol is not supported**, so this example defaults to `http` (port 31112). Your requests to HTTPS sites stay encrypted end to end inside the proxy tunnel, but your proxy username and auth key reach the PacketStream gateway unencrypted. Net::HTTP 0.5.0 and later accept a `p_use_ssl` argument for a TLS connection to the proxy, but the implementation does not verify the proxy's certificate ([ruby/net-http#308](https://github.com/ruby/net-http/issues/308)) and starts the destination's TLS session on the raw socket instead of inside the proxy's TLS session ([ruby/net-http#212](https://github.com/ruby/net-http/issues/212)).

## Run natively

Requires Ruby and Bundler (tested with Ruby 4.0).

```bash
bundle config set --local without development
bundle install
export PACKETSTREAM_USER=your_username
export PACKETSTREAM_AUTH_KEY=your_auth_key
# Optional: PACKETSTREAM_PROXY_PROTOCOL=socks5, PACKETSTREAM_COUNTRY=US, PACKETSTREAM_SESSION=order42
bundle exec ruby main.rb
```

## Run with Docker

```bash
docker build -t packetstream-ruby .
docker run --rm -e PACKETSTREAM_USER -e PACKETSTREAM_AUTH_KEY packetstream-ruby
```

Add `-e PACKETSTREAM_PROXY_PROTOCOL`, `-e PACKETSTREAM_COUNTRY`, or `-e PACKETSTREAM_SESSION` to pass the optional settings.
