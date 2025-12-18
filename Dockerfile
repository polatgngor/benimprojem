# Use Node.js 18 on Alpine Linux for a small image size
FROM node:18-alpine

# Set working directory inside the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json first to leverage Docker cache
COPY package*.json ./

# Install only production dependencies
# If you need devDependencies for building (like some native modules), use 'npm install'
# For pure production run usually 'npm ci --only=production' is best, but let's be safe with 'npm install'
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose the application port (matches PORT in .env)
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
