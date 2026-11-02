// Make two requests through PacketStream and print the exit IP of each.

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.ProxySelector;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Base64;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class Main {
    private static final int HTTP_PORT = 31112;
    private static final Duration TIMEOUT = Duration.ofSeconds(30);

    public static void main(String[] args) {
        // The JDK drops Basic proxy credentials from CONNECT requests unless
        // this property is cleared. It is read once, when the HTTP client
        // classes load, so it must be set before the first HttpClient is built
        // (or passed as -Djdk.http.auth.tunneling.disabledSchemes=).
        System.setProperty("jdk.http.auth.tunneling.disabledSchemes", "");

        String user = require("PACKETSTREAM_USER");
        String authKey = require("PACKETSTREAM_AUTH_KEY");
        String host = env("PACKETSTREAM_PROXY_HOST", "proxy.packetstream.io");
        String protocol = env("PACKETSTREAM_PROXY_PROTOCOL", "http");

        // HttpClient only speaks plain HTTP to a proxy: it cannot open TLS to
        // the proxy (https) and ignores SOCKS proxies, connecting directly.
        if (!protocol.equals("http")) {
            fail("Unsupported PACKETSTREAM_PROXY_PROTOCOL: " + protocol
                    + " (Java's HttpClient supports only http)");
        }

        // Targeting and sticky sessions are suffixes on the auth key
        String password = authKey;
        StringBuilder description = new StringBuilder("Proxy: http://" + host + ":" + HTTP_PORT);
        String country = System.getenv("PACKETSTREAM_COUNTRY");
        if (country != null && !country.isEmpty()) {
            password += "_country-" + country;
            description.append(" country=").append(country);
        }
        String session = System.getenv("PACKETSTREAM_SESSION");
        if (session != null && !session.isEmpty()) {
            password += "_session-" + session;
            description.append(" session=").append(session);
        }
        System.out.println(description);

        // Sent with the CONNECT request only; HttpClient strips Proxy-*
        // headers from the request it sends through the tunnel.
        String proxyAuthorization = "Basic " + Base64.getEncoder().encodeToString(
                (user + ":" + password).getBytes(StandardCharsets.UTF_8));

        // An explicit proxy ignores the http.proxyHost and https.proxyHost
        // system properties; Java never reads HTTP_PROXY or HTTPS_PROXY.
        ProxySelector proxy = ProxySelector.of(new InetSocketAddress(host, HTTP_PORT));
        HttpRequest request = HttpRequest.newBuilder(URI.create("https://ipinfo.io/json"))
                .header("Proxy-Authorization", proxyAuthorization)
                .timeout(TIMEOUT)
                .build();

        for (int n = 1; n <= 2; n++) {
            String body;
            // A new client per request opens a new proxy connection
            try (HttpClient client = HttpClient.newBuilder()
                    .proxy(proxy)
                    .connectTimeout(TIMEOUT)
                    .build()) {
                HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
                if (response.statusCode() != 200) {
                    fail("Request " + n + " failed: HTTP " + response.statusCode());
                }
                body = response.body();
            } catch (IOException | InterruptedException error) {
                // Error messages should not contain the key, but remove it in case
                String message = String.valueOf(error.getMessage()).replace(authKey, "xxxxx");
                fail("Request " + n + " failed: " + error.getClass().getSimpleName() + ": " + message);
                return;
            }

            System.out.println("Request " + n + ": " + field(body, "ip") + "  " + field(body, "country")
                    + "  " + field(body, "city") + "  " + field(body, "org"));
        }
    }

    // The JDK has no JSON parser. ipinfo.io returns flat string fields, so a
    // pattern is enough here; use a JSON library such as Jackson in real code.
    private static String field(String json, String name) {
        Matcher m = Pattern.compile("\"" + name + "\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"").matcher(json);
        return m.find() ? m.group(1) : "null";
    }

    private static String require(String name) {
        String value = System.getenv(name);
        if (value == null || value.isEmpty()) {
            fail("Set " + name);
        }
        return value;
    }

    private static String env(String name, String fallback) {
        String value = System.getenv(name);
        return value == null || value.isEmpty() ? fallback : value;
    }

    private static void fail(String message) {
        System.err.println(message);
        System.exit(1);
    }
}
