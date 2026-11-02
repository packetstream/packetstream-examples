# C#

Makes two requests through PacketStream with .NET's `HttpClient`, each on a new proxy connection, and prints the exit IP of each. It uses `WebProxy` with a `NetworkCredential` and no NuGet packages.

All three protocols work. `SocketsHttpHandler` opens a verified TLS connection to `https://` proxies ([`HttpConnectionPool.cs`](https://github.com/dotnet/runtime/blob/release/10.0/src/libraries/System.Net.Http/src/System/Net/Http/SocketsHttpHandler/ConnectionPool/HttpConnectionPool.cs)), authenticates to SOCKS5 proxies with the username and password, and sends the destination hostname to the SOCKS5 proxy so DNS resolves remotely ([`SocksHelper.cs`](https://github.com/dotnet/runtime/blob/release/10.0/src/libraries/System.Net.Http/src/System/Net/Http/SocketsHttpHandler/SocksHelper.cs)).

## Run

Requires the [.NET 10 SDK](https://dotnet.microsoft.com/download).

```bash
export PACKETSTREAM_USER=your-username
export PACKETSTREAM_AUTH_KEY=your-auth-key
dotnet run
```

Optionally set `PACKETSTREAM_COUNTRY=US`, `PACKETSTREAM_SESSION=order42`, or `PACKETSTREAM_PROXY_PROTOCOL=http` or `socks5`.

## Docker

```bash
docker build -t packetstream-csharp .
docker run --rm -e PACKETSTREAM_USER -e PACKETSTREAM_AUTH_KEY packetstream-csharp
```
