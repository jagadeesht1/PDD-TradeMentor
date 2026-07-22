const express = require('express');
const http = require('http');
const cors = require('cors');
const dotenv = require('dotenv');
const apiRoutes = require('./routes/api');
const websocketService = require('./services/websocketService');

// Load environment variables
dotenv.config();

const app = express();
const port = process.env.PORT || 5000;

// Enable CORS
app.use(cors({
  origin: '*', // Allow all origins for dev/academic demos
  methods: ['GET', 'POST', 'DELETE', 'OPTIONS']
}));

app.use(express.json());

// Main REST routes
app.use('/api', apiRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP', timestamp: new Date().toISOString() });
});

// Create Server and bind express + websockets
const server = http.createServer(app);
const wss = websocketService.initWebSocketServer(server);

// Upgrade requests to WebSocket protocol
server.on('upgrade', (request, socket, head) => {
  if (request.url === '/ws') {
    wss.handleUpgrade(request, socket, head, (ws) => {
      wss.emit('connection', ws, request);
    });
  } else {
    socket.destroy();
  }
});

// Start listening
server.listen(port, () => {
  console.log(`===============================================`);
  console.log(`  TradeMentor Backend listening on port ${port}`);
  console.log(`  WebSocket endpoint: ws://localhost:${port}/ws`);
  console.log(`  REST API endpoint: http://localhost:${port}/api`);
  console.log(`===============================================`);
});

module.exports = server;
