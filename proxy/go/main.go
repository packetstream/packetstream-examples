// Command proxy makes two requests through PacketStream and prints the exit IP of each.
package main

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"
)

var ports = map[string]string{"https": "31111", "http": "31112", "socks5": "31113"}

type ipInfo struct {
	IP      string `json:"ip"`
	Country string `json:"country"`
	City    string `json:"city"`
	Org     string `json:"org"`
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func run() error {
	for _, name := range []string{"PACKETSTREAM_USER", "PACKETSTREAM_AUTH_KEY"} {
		if os.Getenv(name) == "" {
			return fmt.Errorf("set %s", name)
		}
	}
	host := getenv("PACKETSTREAM_PROXY_HOST", "proxy.packetstream.io")
	protocol := getenv("PACKETSTREAM_PROXY_PROTOCOL", "https")
	port, ok := ports[protocol]
	if !ok {
		return fmt.Errorf("unsupported PACKETSTREAM_PROXY_PROTOCOL: %s (use https, http, or socks5)", protocol)
	}

	// socks5h resolves the destination hostname through the proxy
	scheme := protocol
	if protocol == "socks5" {
		scheme = "socks5h"
	}
	proxyURL := &url.URL{Scheme: scheme, Host: host + ":" + port}

	// Targeting and sticky sessions are suffixes on the auth key
	password := os.Getenv("PACKETSTREAM_AUTH_KEY")
	description := "Proxy: " + proxyURL.String()
	if country := os.Getenv("PACKETSTREAM_COUNTRY"); country != "" {
		password += "_country-" + country
		description += " country=" + country
	}
	if session := os.Getenv("PACKETSTREAM_SESSION"); session != "" {
		password += "_session-" + session
		description += " session=" + session
	}
	fmt.Println(description)

	for request := 1; request <= 2; request++ {
		info, err := fetch(proxyURL, os.Getenv("PACKETSTREAM_USER"), password)
		if err != nil {
			// Some error messages repeat the proxy URL, so remove the key
			message := strings.ReplaceAll(err.Error(), url.QueryEscape(password), "xxxxx")
			message = strings.ReplaceAll(message, password, "xxxxx")
			return fmt.Errorf("request %d failed: %s", request, message)
		}
		fmt.Printf("Request %d: %s  %s  %s  %s\n", request, info.IP, info.Country, info.City, info.Org)
	}
	return nil
}

// fetch requests ipinfo.io through the proxy on a new connection.
func fetch(proxyURL *url.URL, user, password string) (*ipInfo, error) {
	transport := http.DefaultTransport.(*http.Transport).Clone()
	// Setting Proxy explicitly ignores HTTP_PROXY, HTTPS_PROXY and NO_PROXY
	transport.Proxy = http.ProxyURL(proxyURL)
	// A new transport per request opens a new proxy connection
	transport.DisableKeepAlives = true
	if proxyURL.Scheme == "socks5h" {
		// The SOCKS5 dialer only reads credentials from the proxy URL
		withAuth := *proxyURL
		withAuth.User = url.UserPassword(user, password)
		transport.Proxy = http.ProxyURL(&withAuth)
	} else {
		// Send the credentials with the CONNECT request rather than in the URL
		token := base64.StdEncoding.EncodeToString([]byte(user + ":" + password))
		transport.ProxyConnectHeader = http.Header{"Proxy-Authorization": {"Basic " + token}}
	}
	client := &http.Client{Transport: transport, Timeout: 30 * time.Second}

	req, err := http.NewRequestWithContext(context.Background(), http.MethodGet, "https://ipinfo.io/json", nil)
	if err != nil {
		return nil, err
	}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected status %s", resp.Status)
	}
	var info ipInfo
	if err := json.NewDecoder(resp.Body).Decode(&info); err != nil {
		return nil, err
	}
	return &info, nil
}

func getenv(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}
