"""Fetch ipinfo.io through PacketStream with a Scrapy spider and print the exit IP."""

import os
import sys

import scrapy
from scrapy.crawler import CrawlerProcess
from w3lib.http import basic_auth_header

# Scrapy's default download handler cannot open a TLS connection to an HTTPS
# proxy for an HTTPS site, and has no SOCKS5 support, so only HTTP is offered.
# The site's own TLS still runs end to end through the CONNECT tunnel.
PORTS = {"http": 31112}


def proxy_settings():
    """Return the proxy URL, the password, and a description."""
    host = os.environ.get("PACKETSTREAM_PROXY_HOST", "proxy.packetstream.io")
    protocol = os.environ.get("PACKETSTREAM_PROXY_PROTOCOL", "http")
    if protocol not in PORTS:
        sys.exit(
            f"Unsupported PACKETSTREAM_PROXY_PROTOCOL: {protocol} "
            "(use http; Scrapy supports neither HTTPS proxies for HTTPS sites nor SOCKS5)"
        )
    proxy_url = f"{protocol}://{host}:{PORTS[protocol]}"

    # Targeting and sticky sessions are suffixes on the auth key
    password = os.environ["PACKETSTREAM_AUTH_KEY"]
    description = f"Proxy: {proxy_url}"
    if country := os.environ.get("PACKETSTREAM_COUNTRY"):
        password += f"_country-{country}"
        description += f" country={country}"
    if session := os.environ.get("PACKETSTREAM_SESSION"):
        password += f"_session-{session}"
        description += f" session={session}"

    return proxy_url, password, description


class ExitIpSpider(scrapy.Spider):
    name = "exit_ip"

    def __init__(self, proxy_url, proxy_auth, **kwargs):
        super().__init__(**kwargs)
        self.proxy_url = proxy_url
        self.proxy_auth = proxy_auth
        self.info = None
        self.error = None

    async def start(self):
        # meta["proxy"] takes precedence over HTTP_PROXY and friends. The
        # credentials go in a separate header rather than in the proxy URL;
        # Scrapy sends it on the CONNECT request to the proxy only.
        yield scrapy.Request(
            "https://ipinfo.io/json",
            meta={"proxy": self.proxy_url},
            headers={"Proxy-Authorization": self.proxy_auth},
            callback=self.parse,
            errback=self.failed,
            dont_filter=True,
        )

    def parse(self, response):
        try:
            self.info = response.json()
        except ValueError as error:
            self.error = f"invalid JSON: {error}"

    def failed(self, failure):
        response = getattr(failure.value, "response", None)
        self.error = f"HTTP {response.status}" if response is not None else str(failure.value)


def main():
    for name in ("PACKETSTREAM_USER", "PACKETSTREAM_AUTH_KEY"):
        if not os.environ.get(name):
            sys.exit(f"Set {name}")

    proxy_url, password, description = proxy_settings()
    print(description)

    process = CrawlerProcess(
        settings={
            "DOWNLOAD_TIMEOUT": 30,
            # Scrapy does not verify TLS certificates unless told to
            "DOWNLOAD_VERIFY_CERTIFICATES": True,
            # One request, so fail fast and report the error ourselves
            "RETRY_ENABLED": False,
            "HTTPERROR_ALLOW_ALL": False,
            "LOG_ENABLED": False,
            "TELNETCONSOLE_ENABLED": False,
        }
    )
    crawler = process.create_crawler(ExitIpSpider)
    process.crawl(crawler, proxy_url=proxy_url, proxy_auth=basic_auth_header(os.environ["PACKETSTREAM_USER"], password))
    process.start()

    spider = crawler.spider
    if spider.info is None:
        # Error messages can repeat request details, so remove the key
        message = (spider.error or "no response").replace(os.environ["PACKETSTREAM_AUTH_KEY"], "xxxxx")
        sys.exit(f"Request 1 failed: {message}")
    info = spider.info
    print(f"Request 1: {info.get('ip')}  {info.get('country')}  {info.get('city')}  {info.get('org')}")


if __name__ == "__main__":
    main()
