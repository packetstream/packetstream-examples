// Open ipinfo.io in Chromium through PacketStream and print the exit IP.
import { chromium } from "playwright";

// Chromium cannot authenticate to a SOCKS5 proxy, so only HTTP(S) is offered
const PORTS = { https: 31111, http: 31112 };

function fail(message) {
  console.error(message);
  process.exit(1);
}

for (const name of ["PACKETSTREAM_USER", "PACKETSTREAM_AUTH_KEY"]) {
  if (!process.env[name]) fail(`Set ${name}`);
}
const authKey = process.env.PACKETSTREAM_AUTH_KEY;
const host = process.env.PACKETSTREAM_PROXY_HOST || "proxy.packetstream.io";
const protocol = process.env.PACKETSTREAM_PROXY_PROTOCOL || "https";
if (!Object.hasOwn(PORTS, protocol)) {
  fail(
    `Unsupported PACKETSTREAM_PROXY_PROTOCOL: ${protocol} (use https or http; ` +
      "Chromium does not support SOCKS5 proxy authentication)",
  );
}
const proxyUrl = `${protocol}://${host}:${PORTS[protocol]}`;

// Targeting and sticky sessions are suffixes on the auth key
let password = authKey;
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

// Error messages can include launch options, so remove the key
function redact(text) {
  return String(text)
    .replaceAll(encodeURIComponent(authKey), "xxxxx")
    .replaceAll(authKey, "xxxxx");
}

let browser;
try {
  // Playwright answers only the proxy's authentication challenge with these
  // credentials. Setting the proxy explicitly ignores HTTP_PROXY and friends,
  // and Chromium resolves the destination hostname through the proxy.
  browser = await chromium.launch({
    proxy: { server: proxyUrl, username: process.env.PACKETSTREAM_USER, password },
    timeout: 30_000,
  });
  const page = await browser.newPage();
  // "commit" returns as soon as the response arrives, so a 407 from the
  // proxy fails straight away instead of waiting for the page to load
  const response = await page.goto("https://ipinfo.io/json", {
    waitUntil: "commit",
    timeout: 30_000,
  });
  if (!response?.ok()) throw new Error(`HTTP ${response?.status()}`);
  const info = await response.json();
  console.log(`Request 1: ${info.ip}  ${info.country}  ${info.city}  ${info.org}`);
} catch (error) {
  // Keep only the first line; Playwright appends a verbose call log
  console.error(redact(`Request 1 failed: ${error.message.split("\n")[0]}`));
  process.exitCode = 1;
} finally {
  await browser?.close();
}
