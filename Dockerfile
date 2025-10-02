# Start from Node 16 image
FROM node:16

# Install Docker CLI
RUN curl -fsSLO https://get.docker.com/builds/Linux/x86_64/docker-17.04.0-ce.tgz \
    && tar xzvf docker-17.04.0-ce.tgz \
    && mv docker/docker /usr/local/bin \
    && rm -r docker docker-17.04.0-ce.tgz

# Set working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package*.json ./
RUN npm install --save

# Copy app files
COPY . .

# Default command
CMD ["node", "index.js"]
