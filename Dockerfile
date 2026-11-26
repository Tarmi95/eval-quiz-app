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

COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/ > /dev/null || exit 1