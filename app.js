// app.js - API Express simple retournant "pong"
const express = require('express');
const app = express();
const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.json({ message: 'pong', timestamp: new Date().toISOString() });
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// On n'écoute que si ce fichier est exécuté directement (pas pendant les tests)
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Serveur démarré sur le port ${PORT}`);
  });
}

module.exports = app;
