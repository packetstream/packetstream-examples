FROM golang:1.27-alpine AS build

# Set the working directory inside the container
WORKDIR /src

# Copy go mod and sum files and download all dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy the source code into the container and build a static binary
COPY main.go ./
RUN CGO_ENABLED=0 go build -trimpath -o /packetstream-example-go .

# Run as a non-root user in a minimal image that includes CA certificates
FROM gcr.io/distroless/static-debian13:nonroot
COPY --from=build /packetstream-example-go /packetstream-example-go
CMD ["/packetstream-example-go"]
