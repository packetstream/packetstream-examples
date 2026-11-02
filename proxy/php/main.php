<?php

// Make two requests through PacketStream and print the exit IP of each.

declare(strict_types=1);

function fail(string $message): never
{
    fwrite(STDERR, $message . PHP_EOL);
    exit(1);
}

function env(string $name, string $default = ''): string
{
    $value = getenv($name);
    return $value === false || $value === '' ? $default : $value;
}

foreach (['PACKETSTREAM_USER', 'PACKETSTREAM_AUTH_KEY'] as $name) {
    if (env($name) === '') {
        fail("Set $name");
    }
}

$host = env('PACKETSTREAM_PROXY_HOST', 'proxy.packetstream.io');
$protocol = env('PACKETSTREAM_PROXY_PROTOCOL', 'https');

// CURLPROXY_SOCKS5_HOSTNAME (socks5h) resolves the destination hostname through the proxy
[$scheme, $port, $type] = match ($protocol) {
    'https' => ['https', 31111, CURLPROXY_HTTPS],
    'http' => ['http', 31112, CURLPROXY_HTTP],
    'socks5' => ['socks5h', 31113, CURLPROXY_SOCKS5_HOSTNAME],
    default => fail("Unsupported PACKETSTREAM_PROXY_PROTOCOL: $protocol (use https, http, or socks5)"),
};

// Targeting and sticky sessions are suffixes on the auth key
$password = env('PACKETSTREAM_AUTH_KEY');
$description = "Proxy: $scheme://$host:$port";
if (($country = env('PACKETSTREAM_COUNTRY')) !== '') {
    $password .= "_country-$country";
    $description .= " country=$country";
}
if (($session = env('PACKETSTREAM_SESSION')) !== '') {
    $password .= "_session-$session";
    $description .= " session=$session";
}
echo $description, PHP_EOL;

foreach ([1, 2] as $request) {
    // A new handle per request opens a new proxy connection
    $curl = curl_init('https://ipinfo.io/json');
    curl_setopt_array($curl, [
        CURLOPT_PROXY => $host,
        CURLOPT_PROXYPORT => $port,
        CURLOPT_PROXYTYPE => $type,
        CURLOPT_PROXYUSERNAME => env('PACKETSTREAM_USER'),
        CURLOPT_PROXYPASSWORD => $password,
        // Setting CURLOPT_PROXY already overrides HTTP_PROXY and HTTPS_PROXY;
        // an empty list also stops NO_PROXY from bypassing the proxy
        CURLOPT_NOPROXY => '',
        CURLOPT_TIMEOUT => 30,
        CURLOPT_RETURNTRANSFER => true,
    ]);

    $body = curl_exec($curl);
    if (!is_string($body)) {
        // Remove the key in case an error message repeats it
        fail("Request $request failed: " . str_replace($password, 'xxxxx', curl_error($curl)));
    }
    $status = curl_getinfo($curl, CURLINFO_RESPONSE_CODE);
    if ($status !== 200) {
        fail("Request $request failed: HTTP status $status");
    }

    try {
        $info = json_decode($body, true, flags: JSON_THROW_ON_ERROR);
    } catch (JsonException $error) {
        fail("Request $request failed: {$error->getMessage()}");
    }
    if (!is_array($info)) {
        fail("Request $request failed: unexpected response");
    }

    $fields = array_map(
        static fn (string $field): string => is_scalar($info[$field] ?? null) ? (string) $info[$field] : '',
        ['ip', 'country', 'city', 'org'],
    );
    echo "Request $request: ", implode('  ', $fields), PHP_EOL;
}
