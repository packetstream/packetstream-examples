package main

import (
	"errors"
	"io"
	"log"
	"net/http"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"

	"golang.org/x/net/proxy"
)

const tunnelTimeout = 10 * time.Second

func main() {
	proxyURLs := os.Getenv("PROXY_URLS")
	if proxyURLs == "" {
		log.Fatal("PROXY_URLS should be a comma separated list of proxy URLs")
	}

	endpoint := "http://ipv4.icanhazip.com"

	for _, proxyURL := range strings.Split(proxyURLs, ",") {
		log.Printf("Using proxy: %s", proxyURL)
		responseBody, err := proxiedRequest(proxyURL, endpoint)
		if err != nil {
			log.Fatal(err)
		}

		log.Printf("Your IP is: %s", responseBody)
	}
}

// proxiedRequest makes a proxied request through the specified proxy.
// It automatically handles HTTP and SOCKS5 proxies based on the scheme of the proxyURL.
func proxiedRequest(proxyURL string, endpoint string) (string, error) {
	// Parse the proxy URL
	p, err := url.Parse(proxyURL)
	if err != nil {
		return "", err
	}

	// Create a client based on the proxy scheme
	var client *http.Client
	switch p.Scheme {
	case "http", "https":
		// HTTP/HTTPS proxy
		client = &http.Client{
			Transport: &http.Transport{
				Proxy: http.ProxyURL(p),
			},
			Timeout: tunnelTimeout,
		}
	case "socks5", "socks5h":
		// SOCKS5 proxy
		dialer, err := proxy.FromURL(p, proxy.Direct)
		if err != nil {
			return "", err
		}
		client = &http.Client{
			Transport: &http.Transport{
				Dial: dialer.Dial,
			},
			Timeout: tunnelTimeout,
		}
	default:
		return "", errors.New("unsupported proxy scheme: " + p.Scheme)
	}

	// Make the request
	resp, err := client.Get(endpoint)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	// Check the response status code
	if resp.StatusCode != http.StatusOK {
		return "", errors.New("bad status code: " + strconv.Itoa(resp.StatusCode))
	}

	// Read the response body
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	return string(body), nil
}
