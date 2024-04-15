import os
import requests
import sys
from urllib.parse import urlparse

def proxied_request(proxy_url, endpoint):
    parsed_url = urlparse(proxy_url)
    proxies = {}

    if parsed_url.scheme.startswith('http') or parsed_url.scheme.startswith('https'):
        proxies = {'http': proxy_url, 'https': proxy_url}
    elif parsed_url.scheme.startswith('socks5'):
        # Ensure that DNS queries are made through the SOCKS proxy
        proxies = {
            'http': f'socks5h://{parsed_url.netloc}',
            'https': f'socks5h://{parsed_url.netloc}'
        }
    else:
        raise ValueError(f"Unsupported proxy scheme: {parsed_url.scheme}")

    try:
        response = requests.get(endpoint, proxies=proxies, timeout=10)
        response.raise_for_status()
        return response.text.strip()
    except requests.RequestException as e:
        return f"Error: {str(e)}"

def main():
    proxy_urls = os.getenv("PROXY_URLS")
    if not proxy_urls:
        sys.exit("PROXY_URLS should be a comma-separated list of proxy URLs")

    endpoint = "http://ipv4.icanhazip.com"

    for proxy_url in proxy_urls.split(','):
        print(f"Using proxy: {proxy_url}")
        result = proxied_request(proxy_url, endpoint)
        print(f"Your IP is: {result}")

if __name__ == "__main__":
    main()

