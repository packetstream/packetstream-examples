// Make two requests through PacketStream and print the exit IP of each.

using System.Net;
using System.Text.Json;

var ports = new Dictionary<string, int> { ["https"] = 31111, ["http"] = 31112, ["socks5"] = 31113 };

foreach (var name in new[] { "PACKETSTREAM_USER", "PACKETSTREAM_AUTH_KEY" })
{
    if (string.IsNullOrEmpty(Environment.GetEnvironmentVariable(name)))
    {
        return Fail($"Set {name}");
    }
}

var user = Environment.GetEnvironmentVariable("PACKETSTREAM_USER")!;
var authKey = Environment.GetEnvironmentVariable("PACKETSTREAM_AUTH_KEY")!;
var host = Env("PACKETSTREAM_PROXY_HOST", "proxy.packetstream.io");
var protocol = Env("PACKETSTREAM_PROXY_PROTOCOL", "https");
if (!ports.TryGetValue(protocol, out var port))
{
    return Fail($"Unsupported PACKETSTREAM_PROXY_PROTOCOL: {protocol} (use https, http, or socks5)");
}

// .NET sends the destination hostname to SOCKS5 proxies, so DNS is remote
var proxyUrl = $"{protocol}://{host}:{port}";

// Targeting and sticky sessions are suffixes on the auth key
var password = authKey;
var description = $"Proxy: {proxyUrl}";
var country = Environment.GetEnvironmentVariable("PACKETSTREAM_COUNTRY");
if (!string.IsNullOrEmpty(country))
{
    password += $"_country-{country}";
    description += $" country={country}";
}
var session = Environment.GetEnvironmentVariable("PACKETSTREAM_SESSION");
if (!string.IsNullOrEmpty(session))
{
    password += $"_session-{session}";
    description += $" session={session}";
}
Console.WriteLine(description);

for (var request = 1; request <= 2; request++)
{
    // A new handler per request opens a new proxy connection. Setting Proxy
    // explicitly ignores HTTP_PROXY, HTTPS_PROXY, and ALL_PROXY.
    using var handler = new SocketsHttpHandler
    {
        UseProxy = true,
        Proxy = new WebProxy(proxyUrl) { Credentials = new NetworkCredential(user, password) },
        ConnectTimeout = TimeSpan.FromSeconds(30),
    };
    using var client = new HttpClient(handler) { Timeout = TimeSpan.FromSeconds(30) };

    try
    {
        using var response = await client.GetAsync(new Uri("https://ipinfo.io/json"));
        response.EnsureSuccessStatusCode();
        using var info = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Console.WriteLine($"Request {request}: {Field(info, "ip")}  {Field(info, "country")}  {Field(info, "city")}  {Field(info, "org")}");
    }
    catch (Exception error) when (error is HttpRequestException or TaskCanceledException or JsonException)
    {
        // Error messages should not contain the key, but remove it in case
        var message = error.GetBaseException().Message.Replace(authKey, "xxxxx", StringComparison.Ordinal);
        return Fail($"Request {request} failed: {message}");
    }
}

return 0;

static string Env(string name, string fallback)
{
    var value = Environment.GetEnvironmentVariable(name);
    return string.IsNullOrEmpty(value) ? fallback : value;
}

static string? Field(JsonDocument info, string name) =>
    info.RootElement.TryGetProperty(name, out var value) ? value.GetString() : null;

static int Fail(string message)
{
    Console.Error.WriteLine(message);
    return 1;
}
