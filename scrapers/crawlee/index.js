// Fetch ipinfo.io through PacketStream with Crawlee and print the exit IP.
import { Configuration, HttpCrawler, log, ProxyConfiguration } from "@crawlee/http";

// Crawlee's HTTP client (got-scraping) accepts only http:// and https:// proxy
// URLs, and with an https:// proxy it checks the proxy's certificate against
// the destination hostname, so every request fails. Use the HTTP port.
const PORTS = { http: 31112 };

function fail(message) {
  console.error(message);
  process.exit(1);
}

for (const name of ["PACKETSTREAM_USER", "PACKETSTREAM_AUTH_KEY"]) {
  if (!process.env[name]) fail(`Set ${name}`);
}
const authKey = process.env.PACKETSTREAM_AUTH_KEY;
const host = process.env.PACKETSTREAM_PROXY_HOST || "proxy.packetstream.io";
const protocol = process.env.PACKETSTREAM_PROXY_PROTOCOL || "http";
if (!Object.hasOwn(PORTS, protocol)) {
  fail(
    `Unsupported PACKETSTREAM_PROXY_PROTOCOL: ${protocol} (Crawlee's HTTP ` +
      "crawlers work only with http)",
  );
}
const proxyUrl = new URL(`${protocol}://${host}:${PORTS[protocol]}`);

// Targeting and sticky sessions are suffixes on the auth key
let password = authKey;
let description = `Proxy: ${proxyUrl.origin}`;
if (process.env.PACKETSTREAM_COUNTRY) {
  password += `_country-${process.env.PACKETSTREAM_COUNTRY}`;
  description += ` country=${process.env.PACKETSTREAM_COUNTRY}`;
}
if (process.env.PACKETSTREAM_SESSION) {
  password += `_session-${process.env.PACKETSTREAM_SESSION}`;
  description += ` session=${process.env.PACKETSTREAM_SESSION}`;
}
console.log(description);

// Crawlee takes proxy credentials only in the proxy URL. The URL setters
// percent-encode them.
proxyUrl.username = process.env.PACKETSTREAM_USER;
proxyUrl.password = password;

// Crawlee's log can include proxy URLs and error details, so turn it off and
// print our own messages with the key removed
log.setLevel(log.LEVELS.OFF);
function redact(text) {
  return String(text)
    .replaceAll(encodeURIComponent(authKey), "xxxxx")
    .replaceAll(authKey, "xxxxx");
}

let info;
let failure = "no response";
const crawler = new HttpCrawler(
  {
    // An explicit proxy also ignores HTTP_PROXY and friends
    proxyConfiguration: new ProxyConfiguration({ proxyUrls: [proxyUrl.href] }),
    // Crawlee ignores TLS certificate errors unless told otherwise
    ignoreSslErrors: false,
    navigationTimeoutSecs: 30,
    // One request, so fail fast and report the error ourselves
    maxRequestRetries: 0,
    requestHandler({ json }) {
      info = json;
    },
    failedRequestHandler(_context, error) {
      // A 407 arrives as a session error with the proxy's reply on line two
      const lines = error.message.split("\n").filter((line) => line.trim());
      failure = lines.find((line) => !line.startsWith("Detected a session error")) ?? lines[0];
    },
  },
  // Keep the request queue in memory instead of writing ./storage
  new Configuration({ persistStorage: false }),
);

await crawler.run(["https://ipinfo.io/json"]);
if (!info?.ip) fail(redact(`Request 1 failed: ${failure}`));
console.log(`Request 1: ${info.ip}  ${info.country}  ${info.city}  ${info.org}`);
