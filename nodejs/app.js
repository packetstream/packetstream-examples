import axios from 'axios';
import { HttpsProxyAgent } from 'https-proxy-agent';
import { SocksProxyAgent } from 'socks-proxy-agent';

const tunnelTimeout = 30000; // 30 seconds

async function main() {
  const proxyURLs = process.env.PACKETSTREAM_PROXY_URLS;
  if (!proxyURLs) {
    console.error("PACKETSTREAM_PROXY_URLS should be a comma-separated list of proxy URLs");
    process.exit(1);
  }

  const endpoint = "https://ipv4.icanhazip.com";

  for (const proxyURL of proxyURLs.split(',')) {
    console.log(`Using proxy: ${redact(proxyURL)}`);
    try {
      const responseBody = await proxiedRequest(proxyURL, endpoint);
      console.log(`Your IP is: ${responseBody}`);
    } catch (error) {
      console.error(`Error: ${error.message}`);
      process.exit(1);
    }
  }
}

// redact returns the proxy URL with its auth key replaced so it is never logged.
function redact(proxyURL) {
  try {
    const url = new URL(proxyURL);
    if (url.password) url.password = 'xxxxx';
    return url.toString();
  } catch {
    return '[invalid proxy URL]';
  }
}

async function proxiedRequest(proxyURL, endpoint) {
  const parsedUrl = new URL(proxyURL);

  let agent;
  if (parsedUrl.protocol.startsWith('http')) {
    agent = new HttpsProxyAgent(proxyURL);
  } else if (parsedUrl.protocol.startsWith('socks')) {
    agent = new SocksProxyAgent(proxyURL);
  } else {
    throw new Error(`Unsupported proxy scheme: ${parsedUrl.protocol}`);
  }

  try {
    // proxy: false stops axios from replacing the agent with HTTP_PROXY/HTTPS_PROXY.
    const response = await axios.get(endpoint, { httpAgent: agent, httpsAgent: agent, proxy: false, timeout: tunnelTimeout });
    return String(response.data).trim();
  } catch (error) {
    throw new Error(`HTTP error: ${error.response ? error.response.status : error.message}`);
  }
}

main();
