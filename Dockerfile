# Use Node 16 as base
FROM node:16

# Set working directory
WORKDIR /usr/src/app

# Copy package files first for caching
COPY package*.json ./

# Install dependencies
RUN npm install --save

# Copy the rest of the app
COPY . .

# Default command (can be overridden)
CMD ["node", "app.js"]
