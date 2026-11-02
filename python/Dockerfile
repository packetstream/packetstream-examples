FROM python:3.15-slim

# Set the working directory in the container
WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the Python script into the container
COPY main.py .

# Print output immediately and run as an unprivileged user
ENV PYTHONUNBUFFERED=1
USER nobody

# Command to run the Python script
CMD ["python", "main.py"]
