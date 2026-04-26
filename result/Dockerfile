FROM node:18-slim AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .

FROM node:18-alpine
RUN apk update && apk upgrade --no-cache
RUN npm install -g npm@latest
WORKDIR /app
COPY package*.json ./
RUN npm install --only=production && npm audit fix --force
COPY --from=build /app/server.js .
COPY --from=build /app/views ./views
USER node

EXPOSE 80
CMD ["node", "server.js"]
