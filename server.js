const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Serve static files
app.use(express.static(__dirname));

// Main route - serve ride_logger.html
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'ride_logger.html'));
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.listen(PORT, () => {
  console.log(`🚗 Ride Data Logger server running on port ${PORT}`);
  console.log(`Visit: http://localhost:${PORT}`);
});
