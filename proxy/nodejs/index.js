// Make two requests through PacketStream and print the exit IP of each.
import { fetch, ProxyAgent, Socks5ProxyAgent } from "undici";

const PORTS = { https: 31111, http: 31112, socks5: 31113 };

function fail(message) {
  console.error(message);
  process.exit(1);
}

for (const name of ["PACKETSTREAM_USER", "PACKETSTREAM_AUTH_KEY"]) {
  if (!process.env[name]) fail(`Set ${name}`);
}
const user = process.env.PACKETSTREAM_USER;
const host = process.env.PACKETSTREAM_PROXY_HOST || "proxy.packetstream.io";
const protocol = process.env.PACKETSTREAM_PROXY_PROTOCOL || "https";
if (!Object.hasOwn(PORTS, protocol)) {
  fail(
    `Unsupported PACKETSTREAM_PROXY_PROTOCOL: ${protocol} (use https, http, or socks5)`,
  );
}
const proxyUrl = `${protocol}://${host}:${PORTS[protocol]}`;

// Targeting and sticky sessions are suffixes on the auth key
let password = process.env.PACKETSTREAM_AUTH_KEY;
let description = `Proxy: ${proxyUrl}`;
if (process.env.PACKETSTREAM_COUNTRY) {
  password += `_country-${process.env.PACKETSTREAM_COUNTRY}`;
  description += ` country=${process.env.PACKETSTREAM_COUNTRY}`;
}
if (process.env.PACKETSTREAM_SESSION) {
  password += `_session-${process.env.PACKETSTREAM_SESSION}`;
  description += ` session=${process.env.PACKETSTREAM_SESSION}`;
}
console.log(description);

function newDispatcher() {
  if (protocol === "socks5") {
    // Undici sends the hostname to the SOCKS5 proxy, so DNS is remote
    return new Socks5ProxyAgent(proxyUrl, { username: user, password });
  }
  // Send the credentials as a Proxy-Authorization header, not in the URL
  const token = `Basic ${Buffer.from(`${user}:${password}`).toString("base64")}`;
  return new ProxyAgent({ uri: proxyUrl, token });
}

// Some error messages repeat the proxy credentials, so remove the key
function redact(text) {
  return String(text)
    .replaceAll(encodeURIComponent(password), "xxxxx")
    .replaceAll(password, "xxxxx");
}

for (const request of [1, 2]) {
  // A new dispatcher per request opens a new proxy connection. Passing it
  // explicitly also ignores HTTP_PROXY, HTTPS_PROXY and NO_PROXY.
  const dispatcher = newDispatcher();
  let info;
  try {
    const response = await fetch("https://ipinfo.io/json", {
      dispatcher,
      signal: AbortSignal.timeout(30_000),
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    info = await response.json();
  } catch (error) {
    // fetch wraps network errors ("fetch failed"), so report the innermost cause
    let reason = error;
    while (reason.cause) reason = reason.cause;
    fail(redact(`Request ${request} failed: ${reason.message}`));
  } finally {
    await dispatcher.close();
  }
  console.log(
    `Request ${request}: ${info.ip}  ${info.country}  ${info.city}  ${info.org}`,
  );
}
