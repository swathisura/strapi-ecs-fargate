# Use Node.js base image
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json first
COPY strapi-app/package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the Strapi app
COPY strapi-app/. ./

# Build Strapi
RUN npm run build

# Expose Strapi port
EXPOSE 1337

# Start Strapi
CMD ["npm", "run", "start"]
