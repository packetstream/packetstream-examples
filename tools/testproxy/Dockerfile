FROM golang:1.27-alpine AS build
WORKDIR /src
COPY go.mod main.go ./
RUN CGO_ENABLED=0 go build -trimpath -o /testproxy .

FROM gcr.io/distroless/static-debian13:nonroot
COPY --from=build /testproxy /testproxy
ENTRYPOINT ["/testproxy"]
