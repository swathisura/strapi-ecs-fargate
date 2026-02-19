# 1. Use Node.js image
FROM node:20-alpine

# 2. Set working directory
WORKDIR /app

# 3. Copy package.json and package-lock.json
COPY package*.json ./

# 4. Install dependencies
RUN npm install

# 5. Copy application code
COPY . .

# 6. Build Strapi
RUN npm run build

# 7. Expose Strapi port
EXPOSE 1337

# 8. Start Strapi
CMD ["npm", "run", "start"]
