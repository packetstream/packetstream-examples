# Security

## Reporting a vulnerability

Please report security issues in these examples, or in PacketStream itself, privately through [PacketStream support](https://packetstream.io/contact-us/) instead of a public issue. Include the example and steps to reproduce.

## Exposed credentials

If you committed or published a PacketStream auth key or API key, rotate it at once: the auth key on the [Proxy Access page](https://app.packetstream.io/dashboard/network_access), and the API key on the [Search API page](https://app.packetstream.io/dashboard/search_api). Rotating revokes the old key immediately. Removing it from Git history does not make it secret again.
