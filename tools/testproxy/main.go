// Command testproxy is a local stand-in for proxy.packetstream.io used by the
// smoke test.
//
// It serves an HTTP proxy on :31112 and a SOCKS5 proxy on :31113, accepts only
// the username and password given in TESTPROXY_USER and TESTPROXY_PASSWORD,
// and forwards accepted requests to the real destination. Each accepted or
// rejected connection is logged so the smoke test can tell that the example
// actually used the proxy with the expected auth-key modifiers.
//
// It does not serve the HTTPS proxy port, because examples would need to
// trust a test certificate. The HTTPS endpoint is covered by the live test.
package main

import (
	"bufio"
	"encoding/base64"
	"errors"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
)

const dialTimeout = 15 * time.Second

func main() {
	user, password := os.Getenv("TESTPROXY_USER"), os.Getenv("TESTPROXY_PASSWORD")
	if user == "" || password == "" {
		log.Fatal("set TESTPROXY_USER and TESTPROXY_PASSWORD")
	}

	creds := credentials{user: user, password: password}

	httpListener, err := net.Listen("tcp", ":31112")
	if err != nil {
		log.Fatal(err)
	}
	socksListener, err := net.Listen("tcp", ":31113")
	if err != nil {
		log.Fatal(err)
	}

	log.Print("testproxy ready: http=:31112 socks5=:31113")

	go serve(socksListener, creds.serveSOCKS5)
	serve(httpListener, creds.serveHTTP)
}

type credentials struct {
	user, password string
}

func (c credentials) check(user, password string) bool {
	return user == c.user && password == c.password
}

func serve(listener net.Listener, handle func(net.Conn)) {
	for {
		conn, err := listener.Accept()
		if err != nil {
			log.Fatal(err)
		}
		go func() {
			defer conn.Close()
			handle(conn)
		}()
	}
}

// serveHTTP handles CONNECT tunnels and absolute-form plain HTTP requests.
func (c credentials) serveHTTP(conn net.Conn) {
	reader := bufio.NewReader(conn)
	for {
		req, err := http.ReadRequest(reader)
		if err != nil {
			return
		}

		user, password, ok := proxyBasicAuth(req)
		if !ok || !c.check(user, password) {
			log.Printf("REJECT http %s %s", req.Method, req.Host)
			_, _ = io.WriteString(conn, "HTTP/1.1 407 Proxy Authentication Required\r\n"+
				"Proxy-Authenticate: Basic realm=\"testproxy\"\r\nContent-Length: 0\r\n\r\n")
			continue
		}

		if req.Method == http.MethodConnect {
			log.Printf("ACCEPT http CONNECT %s", req.Host)
			upstream, err := net.DialTimeout("tcp", req.Host, dialTimeout)
			if err != nil {
				_, _ = io.WriteString(conn, "HTTP/1.1 502 Bad Gateway\r\nContent-Length: 0\r\n\r\n")
				return
			}
			defer upstream.Close()
			_, _ = io.WriteString(conn, "HTTP/1.1 200 Connection established\r\n\r\n")
			pipe(conn, reader, upstream)
			return
		}

		log.Printf("ACCEPT http %s %s", req.Method, req.URL)
		req.RequestURI = ""
		req.Header.Del("Proxy-Authorization")
		req.Header.Del("Proxy-Connection")
		resp, err := http.DefaultTransport.RoundTrip(req)
		if err != nil {
			_, _ = io.WriteString(conn, "HTTP/1.1 502 Bad Gateway\r\nContent-Length: 0\r\n\r\n")
			return
		}
		err = resp.Write(conn)
		_ = resp.Body.Close()
		if err != nil {
			return
		}
	}
}

func proxyBasicAuth(req *http.Request) (string, string, bool) {
	scheme, encoded, ok := strings.Cut(req.Header.Get("Proxy-Authorization"), " ")
	if !ok || !strings.EqualFold(scheme, "Basic") {
		return "", "", false
	}
	decoded, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil {
		return "", "", false
	}
	user, password, ok := strings.Cut(string(decoded), ":")

	return user, password, ok
}

// serveSOCKS5 implements the CONNECT command with username/password
// authentication (RFC 1928 and RFC 1929).
func (c credentials) serveSOCKS5(conn net.Conn) {
	reader := bufio.NewReader(conn)
	if err := c.socks5Handshake(conn, reader); err != nil {
		log.Printf("REJECT socks5: %v", err)
		return
	}

	target, err := socks5ReadRequest(reader)
	if err != nil {
		log.Printf("REJECT socks5: %v", err)
		return
	}

	upstream, err := net.DialTimeout("tcp", target, dialTimeout)
	if err != nil {
		// 0x04: host unreachable.
		_, _ = conn.Write([]byte{5, 4, 0, 1, 0, 0, 0, 0, 0, 0})
		return
	}
	defer upstream.Close()

	log.Printf("ACCEPT socks5 CONNECT %s", target)
	_, _ = conn.Write([]byte{5, 0, 0, 1, 0, 0, 0, 0, 0, 0})
	pipe(conn, reader, upstream)
}

func (c credentials) socks5Handshake(conn net.Conn, reader *bufio.Reader) error {
	header := make([]byte, 2)
	if _, err := io.ReadFull(reader, header); err != nil {
		return err
	}
	if header[0] != 5 {
		return fmt.Errorf("unsupported SOCKS version %d", header[0])
	}
	methods := make([]byte, header[1])
	if _, err := io.ReadFull(reader, methods); err != nil {
		return err
	}
	if !strings.ContainsRune(string(methods), 2) {
		_, _ = conn.Write([]byte{5, 0xff})
		return errors.New("client did not offer username/password authentication")
	}
	if _, err := conn.Write([]byte{5, 2}); err != nil {
		return err
	}

	// Username/password subnegotiation.
	version, err := reader.ReadByte()
	if err != nil || version != 1 {
		return errors.New("bad authentication version")
	}
	user, err := readLengthPrefixed(reader)
	if err != nil {
		return err
	}
	password, err := readLengthPrefixed(reader)
	if err != nil {
		return err
	}
	if !c.check(user, password) {
		_, _ = conn.Write([]byte{1, 1})
		return errors.New("bad credentials")
	}
	_, err = conn.Write([]byte{1, 0})

	return err
}

func socks5ReadRequest(reader *bufio.Reader) (string, error) {
	header := make([]byte, 4)
	if _, err := io.ReadFull(reader, header); err != nil {
		return "", err
	}
	if header[1] != 1 {
		return "", fmt.Errorf("unsupported SOCKS command %d", header[1])
	}

	var host string
	switch header[3] {
	case 1:
		addr := make([]byte, net.IPv4len)
		if _, err := io.ReadFull(reader, addr); err != nil {
			return "", err
		}
		host = net.IP(addr).String()
	case 3:
		name, err := readLengthPrefixed(reader)
		if err != nil {
			return "", err
		}
		host = name
	case 4:
		addr := make([]byte, net.IPv6len)
		if _, err := io.ReadFull(reader, addr); err != nil {
			return "", err
		}
		host = net.IP(addr).String()
	default:
		return "", fmt.Errorf("unsupported address type %d", header[3])
	}

	port := make([]byte, 2)
	if _, err := io.ReadFull(reader, port); err != nil {
		return "", err
	}

	return net.JoinHostPort(host, strconv.Itoa(int(port[0])<<8|int(port[1]))), nil
}

func readLengthPrefixed(reader *bufio.Reader) (string, error) {
	length, err := reader.ReadByte()
	if err != nil {
		return "", err
	}
	value := make([]byte, length)
	if _, err := io.ReadFull(reader, value); err != nil {
		return "", err
	}

	return string(value), nil
}

// pipe copies in both directions until either side closes. The client side
// reads through reader so bytes it already buffered are not lost.
func pipe(client net.Conn, reader *bufio.Reader, upstream net.Conn) {
	var wg sync.WaitGroup
	wg.Add(2)
	go func() {
		defer wg.Done()
		_, _ = io.Copy(upstream, reader)
		closeWrite(upstream)
	}()
	go func() {
		defer wg.Done()
		_, _ = io.Copy(client, upstream)
		closeWrite(client)
	}()
	wg.Wait()
}

func closeWrite(conn net.Conn) {
	if tcp, ok := conn.(*net.TCPConn); ok {
		_ = tcp.CloseWrite()
	}
}
