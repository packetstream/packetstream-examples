FROM rust:1.99 AS build
WORKDIR /src
COPY Cargo.toml Cargo.lock ./
COPY src ./src
RUN cargo build --release --locked

# The nonroot image runs as an unprivileged user and includes CA certificates
FROM gcr.io/distroless/cc-debian13:nonroot
COPY --from=build /src/target/release/packetstream-proxy-example /packetstream-proxy-example
ENTRYPOINT ["/packetstream-proxy-example"]
