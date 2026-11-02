# frozen_string_literal: true

# Make two requests through PacketStream and print the exit IP of each.

require 'json'
require 'net/http'
require 'socksify/http'

PORTS = { 'http' => 31_112, 'socks5' => 31_113 }.freeze
URL = URI('https://ipinfo.io/json')

%w[PACKETSTREAM_USER PACKETSTREAM_AUTH_KEY].each do |name|
  abort "Set #{name}" if ENV.fetch(name, '').empty?
end

host = ENV.fetch('PACKETSTREAM_PROXY_HOST', 'proxy.packetstream.io')
# Net::HTTP neither verifies the proxy's certificate nor tunnels TLS correctly
# through a TLS proxy, so this example defaults to the HTTP proxy port
protocol = ENV.fetch('PACKETSTREAM_PROXY_PROTOCOL', 'http')
abort 'PACKETSTREAM_PROXY_PROTOCOL=https is not supported by Net::HTTP (use http or socks5)' if protocol == 'https'
abort "Unsupported PACKETSTREAM_PROXY_PROTOCOL: #{protocol} (use http or socks5)" unless PORTS.key?(protocol)

# Targeting and sticky sessions are suffixes on the auth key
user = ENV.fetch('PACKETSTREAM_USER')
password = ENV.fetch('PACKETSTREAM_AUTH_KEY').dup
# Socksify sends the hostname to the proxy, which resolves it (socks5h)
description = "Proxy: #{protocol == 'socks5' ? 'socks5h' : protocol}://#{host}:#{PORTS[protocol]}"
if (country = ENV.fetch('PACKETSTREAM_COUNTRY', '')) != ''
  password << "_country-#{country}"
  description << " country=#{country}"
end
if (session = ENV.fetch('PACKETSTREAM_SESSION', '')) != ''
  password << "_session-#{session}"
  description << " session=#{session}"
end
puts description

# Passing the proxy (or nil for SOCKS5) explicitly makes Net::HTTP ignore
# HTTP_PROXY, HTTPS_PROXY and NO_PROXY from the environment
def client(protocol, host, user, password)
  if protocol == 'socks5'
    Net::HTTP.socks_proxy(host, PORTS[protocol], username: user, password: password).new(URL.host, URL.port, nil)
  else
    Net::HTTP.new(URL.host, URL.port, host, PORTS[protocol], user, password)
  end
end

[1, 2].each do |request|
  http = client(protocol, host, user, password)
  http.use_ssl = true
  http.open_timeout = http.read_timeout = http.write_timeout = http.ssl_timeout = 30

  begin
    # Each start block opens a new connection and closes it afterwards
    response = http.start { http.request(Net::HTTP::Get.new(URL)) }
    raise "HTTP status #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    info = JSON.parse(response.body)
  rescue StandardError => e
    # Remove the key in case an error message repeats it
    abort "Request #{request} failed: #{e.message.gsub(password, 'xxxxx')}"
  end

  puts "Request #{request}: #{info.values_at('ip', 'country', 'city', 'org').join('  ')}"
end
