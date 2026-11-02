FROM node:26-alpine

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
COPY package*.json ./
RUN npm ci --omit=dev

# Run as the image's unprivileged user
USER node

# Bundle app source
COPY app.js ./

# Command to run the application
CMD [ "node", "app.js" ]

