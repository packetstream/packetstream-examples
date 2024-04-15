import axios from 'axios';
import { HttpsProxyAgent } from 'https-proxy-agent';
import { SocksProxyAgent } from 'socks-proxy-agent';

const tunnelTimeout = 10000; // 10 seconds

async function main() {
  const proxyURLs = process.env.PACKETSTREAM_PROXY_URLS;
  if (!proxyURLs) {
    console.error("PACKETSTREAM_PROXY_URLS should be a comma-separated list of proxy URLs");
    process.exit(1);
  }

  const endpoint = "https://ipv4.icanhazip.com";

  for (const proxyURL of proxyURLs.split(',')) {
    console.log(`Using proxy: ${proxyURL}`);
    try {
      const responseBody = await proxiedRequest(proxyURL, endpoint);
      console.log(`Your IP is: ${responseBody}`);
    } catch (error) {
      console.error(`Error: ${error.message}`);
      process.exit(1);
    }
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
    const response = await axios.get(endpoint, { httpAgent: agent, httpsAgent: agent, timeout: tunnelTimeout });
    return response.data;
  } catch (error) {
    throw new Error(`HTTP error: ${error.response ? error.response.status : error.message}`);
  }
}

main();
