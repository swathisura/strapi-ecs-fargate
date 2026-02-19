WORKDIR /app
COPY strapi-app/package*.json ./
RUN npm install
COPY strapi-app/. ./
RUN npm run build
EXPOSE 1337
CMD ["npm", "run", "start"]
