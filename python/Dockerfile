FROM python:3.12-alpine

# Install dependencies
RUN apk --no-cache add ca-certificates
RUN pip install --no-cache-dir requests[socks]

# Set the working directory in the container
WORKDIR /app

# Copy the Python script into the container
COPY main.py .

# Command to run the Python script
CMD ["python", "main.py"]

