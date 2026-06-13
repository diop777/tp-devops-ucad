# Dockerfile - Image Docker pour l'application Node.js
FROM node:18-alpine

# Répertoire de travail dans le conteneur
WORKDIR /app

# Copier les fichiers de dépendances en premier (optimisation du cache Docker)
COPY package*.json ./

# Installer uniquement les dépendances de production
RUN npm install --omit=dev

# Copier le reste du code source
COPY . .

# Exposer le port de l'application
EXPOSE 3000

# Commande de démarrage
CMD ["node", "app.js"]
