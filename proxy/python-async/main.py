"""Make two concurrent requests through PacketStream and print the exit IP of each."""

import asyncio
import os
import sys

import httpx

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


async def fetch(request, proxy, password):
    """Fetch https://ipinfo.io/json through the proxy on a new connection."""
    # A new client per request opens a new proxy connection. trust_env=False
    # ignores HTTP_PROXY, HTTPS_PROXY and NO_PROXY from the environment.
    async with httpx.AsyncClient(proxy=proxy, trust_env=False, timeout=30) as client:
        try:
            response = await client.get("https://ipinfo.io/json")
            response.raise_for_status()
            return response.json()
        except (httpx.HTTPError, ValueError) as error:
            # Remove the key in case an error message repeats it
            message = str(error).replace(password, "xxxxx") or type(error).__name__
            raise RuntimeError(f"Request {request} failed: {message}") from None


async def main():
    for name in ("PACKETSTREAM_USER", "PACKETSTREAM_AUTH_KEY"):
        if not os.environ.get(name):
            sys.exit(f"Set {name}")

    proxy_url, password, description = proxy_settings()
    print(description)
    # Pass the credentials separately rather than in the URL
    proxy = httpx.Proxy(proxy_url, auth=(os.environ["PACKETSTREAM_USER"], password))

    # Run both requests at the same time
    try:
        results = await asyncio.gather(fetch(1, proxy, password), fetch(2, proxy, password))
    except RuntimeError as error:
        sys.exit(str(error))

    for request, info in enumerate(results, start=1):
        print(f"Request {request}: {info.get('ip')}  {info.get('country')}  {info.get('city')}  {info.get('org')}")


if __name__ == "__main__":
    asyncio.run(main())
