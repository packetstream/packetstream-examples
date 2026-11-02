"""Open ipinfo.io in Chromium through PacketStream and print the exit IP."""

import os
import sys
from urllib.parse import quote

from playwright.sync_api import Error, sync_playwright

# Chromium cannot authenticate to a SOCKS5 proxy, so only HTTP(S) is offered
PORTS = {"https": 31111, "http": 31112}


def proxy_settings():
    """Return the proxy URL, the password, and a description."""
    host = os.environ.get("PACKETSTREAM_PROXY_HOST", "proxy.packetstream.io")
    protocol = os.environ.get("PACKETSTREAM_PROXY_PROTOCOL", "https")
    if protocol not in PORTS:
        sys.exit(
            f"Unsupported PACKETSTREAM_PROXY_PROTOCOL: {protocol} "
            "(use https or http; Chromium does not support SOCKS5 proxy authentication)"
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


def redact(text):
    # Error messages can include launch options, so remove the key
    key = os.environ["PACKETSTREAM_AUTH_KEY"]
    return text.replace(quote(key, safe=""), "xxxxx").replace(key, "xxxxx")


def main():
    for name in ("PACKETSTREAM_USER", "PACKETSTREAM_AUTH_KEY"):
        if not os.environ.get(name):
            sys.exit(f"Set {name}")

    proxy_url, password, description = proxy_settings()
    print(description)

    with sync_playwright() as playwright:
        # Playwright answers only the proxy's authentication challenge with
        # these credentials. Setting the proxy explicitly ignores HTTP_PROXY and
        # friends, and Chromium resolves the destination hostname through it.
        try:
            browser = playwright.chromium.launch(
                proxy={"server": proxy_url, "username": os.environ["PACKETSTREAM_USER"], "password": password},
                timeout=30_000,
            )
        except Error as error:
            sys.exit(redact(f"Browser launch failed: {error.message.splitlines()[0]}"))

        try:
            page = browser.new_page()
            # "commit" returns as soon as the response arrives, so a 407 from
            # the proxy fails straight away instead of waiting for the page
            response = page.goto("https://ipinfo.io/json", wait_until="commit", timeout=30_000)
            if response is None or not response.ok:
                raise Error(f"HTTP {response.status if response else 'no response'}")
            info = response.json()
        except (Error, ValueError) as error:
            # Keep only the first line; Playwright appends a verbose call log
            message = error.message if isinstance(error, Error) else str(error)
            sys.exit(redact(f"Request 1 failed: {message.splitlines()[0]}"))
        finally:
            browser.close()

    print(f"Request 1: {info.get('ip')}  {info.get('country')}  {info.get('city')}  {info.get('org')}")


if __name__ == "__main__":
    main()
