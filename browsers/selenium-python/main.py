"""Open ipinfo.io in Chrome through PacketStream with Selenium and print the exit IP."""

import json
import os
import sys
from urllib.parse import quote

from selenium import webdriver
from selenium.common.exceptions import WebDriverException
from selenium.webdriver.common.by import By

# Chrome cannot authenticate to a SOCKS5 proxy, so only HTTP(S) is offered
PORTS = {"https": 31111, "http": 31112}


def proxy_settings():
    """Return the proxy URL, the password, and a description."""
    host = os.environ.get("PACKETSTREAM_PROXY_HOST", "proxy.packetstream.io")
    protocol = os.environ.get("PACKETSTREAM_PROXY_PROTOCOL", "https")
    if protocol not in PORTS:
        sys.exit(
            f"Unsupported PACKETSTREAM_PROXY_PROTOCOL: {protocol} "
            "(use https or http; Chrome does not support SOCKS5 proxy authentication)"
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
    # Error messages can include the credentials, so remove the key
    key = os.environ["PACKETSTREAM_AUTH_KEY"]
    return text.replace(quote(key, safe=""), "xxxxx").replace(key, "xxxxx")


def answer_proxy_challenges(driver, username, password):
    """Answer the proxy's authentication challenge, and only the proxy's.

    Chrome asks for proxy credentials in an authentication challenge. The
    DevTools Fetch domain reports whether a challenge came from the proxy or
    from a website, so a website's own 401 never receives the key. Selenium's
    BiDi auth handlers cannot make that distinction in current Chrome.
    """
    devtools, connection = driver.start_devtools()
    fetch = devtools.fetch
    answered = set()
    state = {"refused": False}

    def on_request_paused(event):
        connection.execute(fetch.continue_request(event.request_id))

    def on_auth_required(event):
        if event.auth_challenge.source != "Proxy":
            response = fetch.AuthChallengeResponse(response="Default")
        elif event.request_id in answered:
            # A second challenge for the same request means the key was refused
            state["refused"] = True
            response = fetch.AuthChallengeResponse(response="CancelAuth")
        else:
            answered.add(event.request_id)
            response = fetch.AuthChallengeResponse(response="ProvideCredentials", username=username, password=password)
        connection.execute(fetch.continue_with_auth(event.request_id, response))

    connection.on(fetch.RequestPaused, on_request_paused)
    connection.on(fetch.AuthRequired, on_auth_required)
    connection.execute(fetch.enable(handle_auth_requests=True))
    return state


def main():
    for name in ("PACKETSTREAM_USER", "PACKETSTREAM_AUTH_KEY"):
        if not os.environ.get(name):
            sys.exit(f"Set {name}")

    proxy_url, password, description = proxy_settings()
    print(description)

    options = webdriver.ChromeOptions()
    options.add_argument("--headless=new")
    # --proxy-server overrides HTTP_PROXY and friends, and Chrome resolves the
    # destination hostname through the proxy. It cannot carry credentials.
    options.add_argument(f"--proxy-server={proxy_url}")
    # Keep Chrome's own background traffic off the proxy
    options.add_argument("--disable-background-networking")
    options.add_argument("--disable-component-update")
    # The Docker image sets this because the Chrome sandbox needs privileges a
    # default container does not have
    if os.environ.get("CHROME_NO_SANDBOX") == "1":
        options.add_argument("--no-sandbox")

    try:
        driver = webdriver.Chrome(options=options)
    except WebDriverException as error:
        sys.exit(redact(f"Browser launch failed: {error.msg}"))

    try:
        state = answer_proxy_challenges(driver, os.environ["PACKETSTREAM_USER"], password)
        driver.set_page_load_timeout(30)
        driver.get("https://ipinfo.io/json")
        if state["refused"]:
            raise ValueError("the proxy refused the credentials (HTTP 407)")
        # Selenium cannot read the HTTP status, so parse the page as JSON
        info = json.loads(driver.find_element(By.TAG_NAME, "body").text)
    except (WebDriverException, ValueError) as error:
        message = error.msg if isinstance(error, WebDriverException) else str(error)
        sys.exit(redact(f"Request 1 failed: {(message or type(error).__name__).splitlines()[0]}"))
    finally:
        driver.quit()

    print(f"Request 1: {info.get('ip')}  {info.get('country')}  {info.get('city')}  {info.get('org')}")


if __name__ == "__main__":
    main()
