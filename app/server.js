const express = require('express');

const app = express();
const port = process.env.PORT || 3000;

app.get('/', (_req, res) => {
  res.type('text/plain').send('Hello, new world! ');
});

const server = app.listen(port, () => {
  console.log(`Node service listening on port ${port}`);
});

process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  server.close(() => process.exit(0));
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully...');
  server.close(() => process.exit(0));
});
