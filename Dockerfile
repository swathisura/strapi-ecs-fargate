# 1. Base image
FROM node:20-alpine

# 2. Set working directory
WORKDIR /app

# 3. Copy package files and install dependencies
COPY strapi-app/package*.json ./
RUN npm install

# 4. Copy the rest of the Strapi app
COPY strapi-app/. ./

# 5. Build Strapi
RUN npm run build

# 6. Expose port
EXPOSE 1337

# 7. Start Strapi
CMD ["npm", "run", "start"]
