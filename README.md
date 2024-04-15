# PacketStream Examples
This repository provides a collection of code examples for programmatically accessing the PacketStream residential proxy network. You'll find sample code and Docker configurations to help you integrate PacketStream proxies into your projects.


## Getting Started
To get started, you'll need to sign up for a PacketStream account and obtain an API key. You can sign up for an account at [packetstream.io](https://packetstream.io/). Once you have an account, you can find your API key in the [PacketStream dashboard](https://packetstream.io/dashboard/network_access).

## Examples
- [Bash (curl)](bash)
- [Go](go)
- [Node.js](nodejs)
- [Python](python)

## Running the Examples
Each example is self-contained and can be run independently. To run an example, you'll need to install the required dependencies or use the provided Docker configuration.

```bash
# Clone the repository
git clone git@github.com:packetstream/packetstream-examples.git

# Change to the project directory
cd packetstream-examples

# Change to the example directory for the language you're interested in
cd go

# Run the example with Docker
PROXY_URLS="socks5h://username:auth_key@proxy.packetstream.io:31113,https://username:auth_key@proxy.packetstream.io:31111" ./run.sh

# Or run the example natively
PROXY_URLS="socks5h://username:auth_key@proxy.packetstream.io:31113,https://username:auth_key@proxy.packetstream.io:31111" go run main.go
```

## Environment Variables
- `PROXY_URLS`: A comma-separated list of URLs of PacketStream proxies you want to use. Replace `username` and `auth_key` with your PacketStream username and auth key respectively.

## Contributing
Contributions to this repository are welcome. If you have an example or improvement you'd like to share, feel free to open a pull request.

## License
This repository is licensed under the MIT License. See the [LICENSE](LICENSE) file for more information.

## Support
If you encounter any issues or have questions about using PacketStream proxies, please contact [PacketStream support](https://packetstream.io/support/contact).

## About PacketStream
PacketStream is a residential proxy network that enables businesses to access the web through a pool of residential IPs. With PacketStream, you can gather data, scrape websites, and perform other web-related tasks with requests originating from real residential ISPs all over the world.

For more information, visit [PacketStream.io](https://packetstream.io/).
