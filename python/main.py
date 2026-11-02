import os
import sys
from urllib.parse import urlsplit, urlunsplit

import requests


def redact(proxy_url):
    """Return the proxy URL with its auth key replaced so it is never logged."""
    parts = urlsplit(proxy_url)
    if parts.password is None:
        return proxy_url
    netloc = f"{parts.username}:xxxxx@{parts.hostname}"
    if parts.port:
        netloc += f":{parts.port}"
    return urlunsplit(parts._replace(netloc=netloc))


def proxied_request(proxy_url, endpoint):
    scheme = urlsplit(proxy_url).scheme
    if scheme in ("http", "https", "socks5h"):
        proxies = {"http": proxy_url, "https": proxy_url}
    elif scheme == "socks5":
        # Ensure that DNS queries are made through the SOCKS proxy
        proxy_url = "socks5h" + proxy_url[len("socks5"):]
        proxies = {"http": proxy_url, "https": proxy_url}
    else:
        raise ValueError(f"Unsupported proxy scheme: {scheme}")

    with requests.Session() as session:
        # Ignore HTTP_PROXY/HTTPS_PROXY so the PacketStream proxy is always used
        session.trust_env = False
        response = session.get(endpoint, proxies=proxies, timeout=30)
        response.raise_for_status()
        return response.text.strip()


def main():
    proxy_urls = os.getenv("PACKETSTREAM_PROXY_URLS")
    if not proxy_urls:
        sys.exit("PACKETSTREAM_PROXY_URLS should be a comma-separated list of proxy URLs")

    endpoint = "https://ipv4.icanhazip.com"

    for proxy_url in proxy_urls.split(","):
        print(f"Using proxy: {redact(proxy_url)}")
        try:
            result = proxied_request(proxy_url, endpoint)
        except (requests.RequestException, ValueError) as e:
            message = str(e)
            password = urlsplit(proxy_url).password
            if password:
                # Some error messages repeat the proxy URL
                message = message.replace(password, "xxxxx")
            sys.exit(f"Request through {redact(proxy_url)} failed: {message}")
        print(f"Your IP is: {result}")


if __name__ == "__main__":
    main()
