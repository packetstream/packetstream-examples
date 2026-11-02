// Read a web page as Markdown with the PacketStream Fetch API, following long pages.

const API_URL = "https://api.packetstream.io/v1/fetch";
// Each part is a separate fetch and is billed separately, so stop after a few
const MAX_PARTS = 3;

const apiKey = process.env.PACKETSTREAM_API_KEY;
if (!apiKey) fail("Set PACKETSTREAM_API_KEY");

const body = { url: process.argv[2] ?? "https://example.com" };
// Optional: a small max_length splits even a short page into parts
const maxLength = process.env.PACKETSTREAM_FETCH_MAX_LENGTH;
if (maxLength) {
  if (!/^\d+$/.test(maxLength)) fail("PACKETSTREAM_FETCH_MAX_LENGTH must be a whole number");
  body.max_length = Number(maxLength);
}
console.log(`Fetch: ${body.url}`);

let truncated = true;
for (let part = 1; part <= MAX_PARTS && truncated; part++) {
  const page = await fetchPart(body);
  if (part === 1) {
    console.log(`Title: ${page.title}`);
    console.log(`Final URL: ${page.final_url}`);
    console.log(`Status: ${page.status_code}`);
  }
  const end = page.start_index + page.returned_length;
  console.log(`\n--- Part ${part}: characters ${page.start_index} to ${end} of ${page.total_length} ---\n`);
  console.log(page.content);

  // Send the same request again, starting where this part ended
  truncated = page.truncated;
  body.start_index = page.next_start_index;
}
if (truncated) console.log(`\nStopped after ${MAX_PARTS} parts. Continue with start_index=${body.start_index}.`);

async function fetchPart(requestBody) {
  let response;
  let payload;
  try {
    response = await fetch(API_URL, {
      method: "POST",
      headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify(requestBody),
      // The server finishes or gives up within 25 seconds, so wait a little longer
      signal: AbortSignal.timeout(40_000),
    });
    payload = await response.json().catch(() => ({}));
  } catch (error) {
    fail(`Request failed: ${error.cause?.message ?? error.message}`);
  }
  if (!response.ok) {
    const error = payload?.error;
    fail(error ? `Error ${response.status}: ${error.code}: ${error.message}` : `Error ${response.status}: unexpected response`);
  }
  return payload.page;
}

function fail(message) {
  console.error(message);
  process.exit(1);
}
