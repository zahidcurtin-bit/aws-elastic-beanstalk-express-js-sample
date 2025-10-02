# Use Node 16 as the base image
FROM node:16

# Set working directory inside container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json (if exists)
COPY package*.json ./

# Install dependencies and save them
RUN npm install --save

# Copy the rest of the app source code
COPY . .

# Expose the port your app runs on (example: 3000)
EXPOSE 3000

# Start the app
CMD ["node", "index.js"]
