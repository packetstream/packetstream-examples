FROM golang:1.27-alpine AS build
WORKDIR /src
COPY go.mod main.go ./
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /search-example .

# The nonroot image runs as an unprivileged user and includes CA certificates
FROM gcr.io/distroless/static-debian13:nonroot
COPY --from=build /search-example /search-example
ENTRYPOINT ["/search-example"]
