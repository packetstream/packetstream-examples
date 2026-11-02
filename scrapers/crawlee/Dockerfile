FROM node:26-alpine

WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY index.js .

# Run as the unprivileged user that ships with the image
USER node
CMD ["node", "index.js"]
