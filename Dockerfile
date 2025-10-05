FROM node:16

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies for runtime
RUN npm install --save

# Copy rest of the source code
COPY . .

# Expose application port
EXPOSE 8080

# Start app
CMD ["npm", "start"]
