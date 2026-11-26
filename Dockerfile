# ---------- Étape 1 : construction ----------
FROM node:24-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

# ---------- Étape 2 : image finale (non-root) ----------
FROM nginxinc/nginx-unprivileged:alpine

# apk upgrade exige root : on y passe temporairement
USER root
RUN apk upgrade --no-cache
# puis on revient à l'utilisateur non privilégié
USER nginx

# Adresse du backend : valeur par défaut pour le local (docker compose)
# Sur Azure, elle est remplacée par la variable BACKEND_HOST=backend
ENV BACKEND_HOST=backend:3007

# Modèle de configuration : nginx remplace ${BACKEND_HOST} au démarrage
COPY --chown=nginx:nginx nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/ > /dev/null || exit 1