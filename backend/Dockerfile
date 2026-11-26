# 1. Image de base
FROM node:20-alpine

# 2. Environnement de production
ENV NODE_ENV=production

# 3. Dossier de travail
WORKDIR /app

# 4. Dépendances d'abord (cache Docker)
COPY package.json ./
RUN npm install --omit=dev && npm cache clean --force

# 5. Puis le code
COPY server.js ./

# 6. Sécurité : utilisateur non-root
USER node

# 7. Port documenté
EXPOSE 3007

# 8. Vérification de santé
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3007/health || exit 1

# 9. Démarrage
CMD ["node", "server.js"]