package main

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"

	"golang.org/x/net/proxy"
)

const tunnelTimeout = 30 * time.Second

func main() {
	proxyURLs := os.Getenv("PACKETSTREAM_PROXY_URLS")
	if proxyURLs == "" {
		log.Fatal("PACKETSTREAM_PROXY_URLS should be a comma separated list of proxy URLs")
	}

	endpoint := "https://ipv4.icanhazip.com"

	for _, proxyURL := range strings.Split(proxyURLs, ",") {
		p, err := url.Parse(proxyURL)
		if err != nil {
			// The parse error would echo the URL and its credentials.
			log.Fatal("invalid proxy URL in PACKETSTREAM_PROXY_URLS")
		}

		// Redacted() replaces the password so the auth key is never logged.
		log.Printf("Using proxy: %s", p.Redacted())
		responseBody, err := proxiedRequest(p, endpoint)
		if err != nil {
			log.Fatal(err)
		}

		log.Printf("Your IP is: %s", strings.TrimSpace(responseBody))
	}
}

// proxiedRequest makes a proxied request through the specified proxy.
// It automatically handles HTTP and SOCKS5 proxies based on the scheme of the proxy URL.
func proxiedRequest(p *url.URL, endpoint string) (string, error) {
	// Clone the default transport to keep its TLS, HTTP/2 and timeout settings.
	// Setting Proxy explicitly also stops HTTP_PROXY/HTTPS_PROXY from applying.
	transport := http.DefaultTransport.(*http.Transport).Clone() //nolint:forcetypeassert // DefaultTransport is always *http.Transport.

	switch p.Scheme {
	case "http", "https":
		// HTTP/HTTPS proxy
		transport.Proxy = http.ProxyURL(p)
	case "socks5", "socks5h":
		// SOCKS5 proxy
		dialer, err := proxy.FromURL(p, proxy.Direct)
		if err != nil {
			return "", fmt.Errorf("create SOCKS5 dialer: %w", err)
		}
		contextDialer, ok := dialer.(proxy.ContextDialer)
		if !ok {
			return "", errors.New("SOCKS5 dialer does not support contexts")
		}
		transport.Proxy = nil
		transport.DialContext = func(ctx context.Context, network, addr string) (net.Conn, error) {
			return contextDialer.DialContext(ctx, network, addr)
		}
	default:
		return "", fmt.Errorf("unsupported proxy scheme: %s", p.Scheme)
	}

	client := &http.Client{Transport: transport, Timeout: tunnelTimeout}
	defer client.CloseIdleConnections()

	// Make the request
	resp, err := client.Get(endpoint)
	if err != nil {
		return "", fmt.Errorf("request through %s: %w", p.Redacted(), err)
	}
	defer resp.Body.Close()

	// Check the response status code
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("bad status code: %d", resp.StatusCode)
	}

	// Read the response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("read response: %w", err)
	}

	return string(body), nil
}
