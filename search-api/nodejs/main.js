// Run one Google search with the PacketStream Search API and print the results.

const API_URL = "https://api.packetstream.io/v1/search";

const apiKey = process.env.PACKETSTREAM_API_KEY;
if (!apiKey) {
  console.error("Set PACKETSTREAM_API_KEY");
  process.exit(1);
}

// Only query is required. Leave out type and country to use the defaults: search and us.
const body = { query: process.argv.slice(2).join(" ") || "residential proxy" };
if (process.env.PACKETSTREAM_SEARCH_TYPE) body.type = process.env.PACKETSTREAM_SEARCH_TYPE;
if (process.env.PACKETSTREAM_SEARCH_COUNTRY) body.country = process.env.PACKETSTREAM_SEARCH_COUNTRY;
console.log(`Search: type=${body.type ?? "search"} country=${body.country ?? "us"} query=${JSON.stringify(body.query)}`);

let response;
let payload;
try {
  response = await fetch(API_URL, {
    method: "POST",
    headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
    body: JSON.stringify(body),
    // The server finishes or gives up within 25 seconds, so wait a little longer
    signal: AbortSignal.timeout(40_000),
  });
  payload = await response.json().catch(() => ({}));
} catch (error) {
  console.error(`Request failed: ${error.cause?.message ?? error.message}`);
  process.exit(1);
}

if (!response.ok) {
  const error = payload?.error;
  console.error(
    error ? `Error ${response.status}: ${error.code}: ${error.message}` : `Error ${response.status}: unexpected response`,
  );
  process.exit(1);
}

console.log(`Results: ${payload.result_count}`);
// ai_mode returns its answer in payload.ai_mode and has no results list
for (const result of payload.results ?? []) {
  // autocomplete items carry a suggestion instead of a title and URL
  const title = result.title ?? result.suggestion ?? "";
  console.log(`${result.position}. ${title}  ${result.url ?? ""}`.trimEnd());
}
