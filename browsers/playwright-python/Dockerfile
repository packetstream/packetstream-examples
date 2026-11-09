# The image tag must match the playwright version in requirements.txt, because
# each Playwright release expects its own browser builds
FROM mcr.microsoft.com/playwright/python:v1.64.1-noble

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --break-system-packages -r requirements.txt
COPY main.py .

# Print output immediately and run as the unprivileged user that ships with the image
ENV PYTHONUNBUFFERED=1
USER pwuser
CMD ["python", "main.py"]
