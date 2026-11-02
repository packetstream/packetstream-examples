FROM python:3.15-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.py .

# Print output immediately and run as an unprivileged user
ENV PYTHONUNBUFFERED=1
USER nobody
CMD ["python", "main.py"]
