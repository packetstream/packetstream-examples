FROM node:26-alpine

WORKDIR /app
COPY package.json main.js ./

# The node image includes an unprivileged user named node
USER node
ENTRYPOINT ["node", "main.js"]
