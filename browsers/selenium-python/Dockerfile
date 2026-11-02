FROM python:3.15-slim

# Debian's Chromium and its matching ChromeDriver
RUN apt-get update \
  && apt-get install -y --no-install-recommends chromium chromium-driver \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY main.py .

# Use the installed driver instead of letting Selenium Manager download one,
# print output immediately, and run as an unprivileged user
ENV SE_CHROMEDRIVER=/usr/bin/chromedriver \
  CHROME_NO_SANDBOX=1 \
  HOME=/tmp \
  PYTHONUNBUFFERED=1
USER nobody
CMD ["python", "main.py"]
