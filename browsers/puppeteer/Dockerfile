FROM node:26-trixie-slim

# Use Debian's Chromium instead of the Chrome build Puppeteer downloads,
# because Debian also supplies the libraries it needs
RUN apt-get update \
  && apt-get install -y --no-install-recommends chromium \
  && rm -rf /var/lib/apt/lists/*
ENV PUPPETEER_SKIP_DOWNLOAD=1 \
  PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium \
  CHROME_NO_SANDBOX=1

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts && npm cache clean --force
COPY index.js .

# Run as the unprivileged user that ships with the image
USER node
CMD ["node", "index.js"]
