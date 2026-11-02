"""Make two requests through PacketStream and print the exit IP of each."""

import os
import sys
from urllib.parse import quote

import requests

PORTS = {"https": 31111, "http": 31112, "socks5": 31113}


def proxy_settings():
    """Return the proxy URL without credentials, the password, and a description."""
    host = os.environ.get("PACKETSTREAM_PROXY_HOST", "proxy.packetstream.io")
    protocol = os.environ.get("PACKETSTREAM_PROXY_PROTOCOL", "https")
    if protocol not in PORTS:
        sys.exit(f"Unsupported PACKETSTREAM_PROXY_PROTOCOL: {protocol} (use https, http, or socks5)")

    # socks5h resolves the destination hostname through the proxy
    scheme = "socks5h" if protocol == "socks5" else protocol
    proxy_url = f"{scheme}://{host}:{PORTS[protocol]}"

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


def with_credentials(proxy_url, username, password):
    # Requests reads proxy credentials from the URL. Percent-encode them in
    # case they contain reserved characters.
    scheme, rest = proxy_url.split("://", 1)
    return f"{scheme}://{quote(username, safe='')}:{quote(password, safe='')}@{rest}"


def main():
    for name in ("PACKETSTREAM_USER", "PACKETSTREAM_AUTH_KEY"):
        if not os.environ.get(name):
            sys.exit(f"Set {name}")

    proxy_url, password, description = proxy_settings()
    print(description)
    proxy = with_credentials(proxy_url, os.environ["PACKETSTREAM_USER"], password)

    for request in (1, 2):
        # A new session per request opens a new proxy connection
        with requests.Session() as session:
            # Ignore HTTP_PROXY, HTTPS_PROXY and NO_PROXY from the environment
            session.trust_env = False
            try:
                response = session.get(
                    "https://ipinfo.io/json",
                    proxies={"http": proxy, "https": proxy},
                    timeout=30,
                )
                response.raise_for_status()
                info = response.json()
            except (requests.RequestException, ValueError) as error:
                # Some error messages repeat the proxy URL, so remove the key
                message = str(error).replace(quote(password, safe=""), "xxxxx").replace(password, "xxxxx")
                sys.exit(f"Request {request} failed: {message}")

        print(f"Request {request}: {info.get('ip')}  {info.get('country')}  {info.get('city')}  {info.get('org')}")


if __name__ == "__main__":
    main()
