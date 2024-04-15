FROM golang:1.22-alpine

# Install dependencies
RUN apk --no-cache add ca-certificates

# Set the working directory inside the container
WORKDIR /app

# Copy go mod and sum files
COPY go.mod ./
COPY go.sum ./

# Download all dependencies
RUN go mod download

# Copy the source code into the container
COPY main.go ./

# Build the application
RUN go build --o ./packetstream-example-go

# Command to run the executable
CMD ["./packetstream-example-go"]
