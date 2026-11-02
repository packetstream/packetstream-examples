// Open ipinfo.io in Chrome through PacketStream and print the exit IP.
import puppeteer from "puppeteer";

// Chrome cannot authenticate to a SOCKS5 proxy, so only HTTP(S) is offered
const PORTS = { https: 31111, http: 31112 };

function fail(message) {
  console.error(message);
  process.exit(1);
}

for (const name of ["PACKETSTREAM_USER", "PACKETSTREAM_AUTH_KEY"]) {
  if (!process.env[name]) fail(`Set ${name}`);
}
const user = process.env.PACKETSTREAM_USER;
const authKey = process.env.PACKETSTREAM_AUTH_KEY;
const host = process.env.PACKETSTREAM_PROXY_HOST || "proxy.packetstream.io";
const protocol = process.env.PACKETSTREAM_PROXY_PROTOCOL || "https";
if (!Object.hasOwn(PORTS, protocol)) {
  fail(
    `Unsupported PACKETSTREAM_PROXY_PROTOCOL: ${protocol} (use https or http; ` +
      "Chrome does not support SOCKS5 proxy authentication)",
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

// Error messages can include the credentials, so remove the key
function redact(text) {
  return String(text)
    .replaceAll(encodeURIComponent(authKey), "xxxxx")
    .replaceAll(authKey, "xxxxx");
}

// Chrome takes the proxy address on the command line but asks for its
// credentials in an authentication challenge. page.authenticate() would answer
// every challenge, including a website's own 401, so this handler answers only
// challenges from the proxy, once per request.
async function answerProxyChallenges(page) {
  const cdp = await page.createCDPSession();
  const answered = new Set();
  cdp.on("Fetch.requestPaused", ({ requestId }) => {
    cdp.send("Fetch.continueRequest", { requestId }).catch(() => {});
  });
  cdp.on("Fetch.authRequired", ({ requestId, authChallenge }) => {
    let authChallengeResponse = { response: "Default" };
    if (authChallenge.source === "Proxy") {
      // A second challenge for the same request means the proxy refused the key
      authChallengeResponse = answered.has(requestId)
        ? { response: "CancelAuth" }
        : { response: "ProvideCredentials", username: user, password };
      answered.add(requestId);
    }
    cdp.send("Fetch.continueWithAuth", { requestId, authChallengeResponse }).catch(() => {});
  });
  await cdp.send("Fetch.enable", { handleAuthRequests: true });
}

const args = [`--proxy-server=${proxyUrl}`];
// The Docker image sets this because the Chrome sandbox needs privileges a
// default container does not have
if (process.env.CHROME_NO_SANDBOX === "1") args.push("--no-sandbox");

let browser;
try {
  // --proxy-server overrides HTTP_PROXY and friends, and Chrome resolves the
  // destination hostname through the proxy
  browser = await puppeteer.launch({ args, timeout: 30_000 });
  const page = await browser.newPage();
  await answerProxyChallenges(page);
  const response = await page.goto("https://ipinfo.io/json", {
    waitUntil: "domcontentloaded",
    timeout: 30_000,
  });
  if (!response?.ok()) throw new Error(`HTTP ${response?.status()}`);
  const info = await response.json();
  console.log(`Request 1: ${info.ip}  ${info.country}  ${info.city}  ${info.org}`);
} catch (error) {
  console.error(redact(`Request 1 failed: ${error.message.split("\n")[0]}`));
  process.exitCode = 1;
} finally {
  await browser?.close();
}
