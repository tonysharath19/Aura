const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static frontend files
app.use(express.static(path.join(__dirname, '..', 'frontend')));

// Basic route
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', message: 'Aura API is running' });
});

// Start server
app.listen(PORT, () => {
  console.log(`Aura server running on http://localhost:${PORT}`);
});
