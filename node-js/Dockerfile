FROM node:21-alpine

# Install dependencies
RUN apk --no-cache add ca-certificates

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
COPY package*.json ./
RUN npm install

# Bundle app source
COPY app.js ./

# Command to run the application
CMD [ "node", "app.js" ]

