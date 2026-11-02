# The image tag must match the playwright version in package.json, because
# each Playwright release expects its own browser builds
FROM mcr.microsoft.com/playwright:v1.64.0-noble

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY index.js .

# Run as the unprivileged user that ships with the image
USER pwuser
CMD ["node", "index.js"]
