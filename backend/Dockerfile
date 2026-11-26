# Node 24 LTS (Node 20 en fin de vie depuis avril 2026)
FROM node:24-alpine

# Mise à jour des paquets système Alpine
RUN apk upgrade --no-cache

ENV NODE_ENV=production
WORKDIR /app

# Dépendances, puis suppression de npm/yarn (inutiles à l'exécution)
COPY package.json ./
RUN npm install --omit=dev && npm cache clean --force \
 && rm -rf /usr/local/lib/node_modules/npm /usr/local/bin/npm /usr/local/bin/npx \
           /opt/yarn* /usr/local/bin/yarn /usr/local/bin/yarnpkg

COPY server.js ./
USER node
EXPOSE 3007

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3007/health || exit 1

CMD ["node", "server.js"]