# ===== Stage 1: Build =====
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
ARG NEXUS_URL=https://registry.npmjs.org/
RUN npm config set strict-ssl false && \
    npm ci --registry=${NEXUS_URL} --only=production && \
    npm cache clean --force

# ===== Stage 2: Production image =====
FROM node:20-alpine
RUN apk update && apk upgrade --no-cache && \
    rm -rf /var/cache/apk/*
WORKDIR /app
COPY --from=build /app/node_modules ./node_modules
COPY server.js .
COPY views ./views
USER node
EXPOSE 4000
CMD ["node", "server.js"]
