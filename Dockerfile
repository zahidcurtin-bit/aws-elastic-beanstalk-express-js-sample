# Node 16 base image    
FROM node:16

# Set working directory
WORKDIR /usr/src/app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install --save

# Copy all source code
COPY . .

# Expose application port (default Express uses 3000)
EXPOSE 3000

# Start application
CMD ["npm", "start"]