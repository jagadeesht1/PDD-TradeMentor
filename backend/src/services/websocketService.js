const WebSocket = require('ws');
const rulesEngineService = require('./rulesEngineService');

// In-memory stock prices
const stocks = {
  AAPL: { ticker: 'AAPL', companyName: 'Apple Inc.', price: 180.50, change: 1.50, changePercent: 0.84, volume: 1500000, rsi: 45.0, history: [180.0, 180.1, 180.3, 180.5] },
  TSLA: { ticker: 'TSLA', companyName: 'Tesla Inc.', price: 175.20, change: -2.30, changePercent: -1.30, volume: 2400000, rsi: 35.0, history: [178.0, 177.0, 176.2, 175.2] },
  MSFT: { ticker: 'MSFT', companyName: 'Microsoft Corp.', price: 420.80, change: 4.10, changePercent: 0.98, volume: 1100000, rsi: 55.0, history: [416.0, 418.0, 419.5, 420.8] },
  GOOG: { ticker: 'GOOG', companyName: 'Alphabet Inc.', price: 172.10, change: 0.80, changePercent: 0.47, volume: 900000, rsi: 48.0, history: [171.0, 171.5, 171.8, 172.1] },
  RELIANCE: { ticker: 'RELIANCE', companyName: 'Reliance Industries', price: 2950.00, change: 25.00, changePercent: 0.85, volume: 800000, rsi: 62.0, history: [2920, 2930, 2940, 2950] },
  INFY: { ticker: 'INFY', companyName: 'Infosys Ltd.', price: 1450.00, change: -15.00, changePercent: -1.02, volume: 600000, rsi: 29.0, history: [1470, 1465, 1458, 1450] }
};

let wss;
const clientSubscriptions = new Map(); // client socket -> Set of tickers

function initWebSocketServer(server) {
  wss = new WebSocket.Server({ noServer: true });

  wss.on('connection', (ws) => {
    console.log('Client connected to WebSocket');
    clientSubscriptions.set(ws, new Set());

    ws.on('message', (message) => {
      try {
        const data = JSON.parse(message);
        if (data.action === 'subscribe') {
          const subs = clientSubscriptions.get(ws);
          data.tickers.forEach(ticker => {
            if (stocks[ticker]) {
              subs.add(ticker);
              // Send initial state
              ws.send(JSON.stringify({ type: 'tick', ...stocks[ticker] }));
            }
          });
          console.log(`Client subscribed to: ${Array.from(subs).join(', ')}`);
        } else if (data.action === 'unsubscribe') {
          const subs = clientSubscriptions.get(ws);
          data.tickers.forEach(ticker => subs.delete(ticker));
        }
      } catch (err) {
        console.error('Error parsing WS message:', err);
      }
    });

    ws.on('close', () => {
      clientSubscriptions.delete(ws);
      console.log('Client disconnected from WebSocket');
    });
  });

  // Start tick generator loop (every 2 seconds)
  setInterval(generateTicks, 2000);

  return wss;
}

function generateTicks() {
  Object.keys(stocks).forEach(ticker => {
    const stock = stocks[ticker];
    // Don't modify if admin just set manual value recently (we can random walk normally)
    const drift = (Math.random() - 0.49) * (stock.price * 0.002); // slight positive bias
    stock.price = parseFloat((stock.price + drift).toFixed(2));
    stock.change = parseFloat((stock.price - stock.history[0]).toFixed(2));
    stock.changePercent = parseFloat(((stock.change / stock.history[0]) * 100).toFixed(2));
    stock.volume += Math.floor(Math.random() * 5000);

    // Update historical prices & compute simple mock RSI
    stock.history.push(stock.price);
    if (stock.history.length > 14) stock.history.shift();

    const gains = [];
    const losses = [];
    for (let i = 1; i < stock.history.length; i++) {
      const diff = stock.history[i] - stock.history[i - 1];
      if (diff > 0) {
        gains.push(diff);
        losses.push(0);
      } else {
        gains.push(0);
        losses.push(Math.abs(diff));
      }
    }

    if (gains.length > 0) {
      const avgGain = gains.reduce((a, b) => a + b, 0) / gains.length;
      const avgLoss = losses.reduce((a, b) => a + b, 0) / losses.length;
      const rs = avgLoss === 0 ? 100 : avgGain / avgLoss;
      stock.rsi = parseFloat((100 - (100 / (1 + rs))).toFixed(2));
    }

    // Broadcast to subscribed clients
    broadcastTick(stock);

    // Evaluate in backend rules engine
    rulesEngineService.evaluateStockRules(stock);
  });
}

function broadcastTick(stock) {
  if (!wss) return;
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      const subs = clientSubscriptions.get(client);
      if (subs && subs.has(stock.ticker)) {
        client.send(JSON.stringify({ type: 'tick', ...stock }));
      }
    }
  });
}

// Allows admin controls to manually override a stock price/metrics for testing
function adminSetStockValue(ticker, updates) {
  if (!stocks[ticker]) return false;
  stocks[ticker] = {
    ...stocks[ticker],
    ...updates,
    price: parseFloat(updates.price || stocks[ticker].price),
    rsi: parseFloat(updates.rsi !== undefined ? updates.rsi : stocks[ticker].rsi)
  };
  
  // Push changes instantly
  broadcastTick(stocks[ticker]);
  rulesEngineService.evaluateStockRules(stocks[ticker]);
  return true;
}

function getStockDetails(ticker) {
  return stocks[ticker] || null;
}

function getStocksList() {
  return Object.values(stocks);
}

function broadcastAlert(alert) {
  if (!wss) return;
  wss.clients.forEach(client => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify({ type: 'alert', ...alert }));
    }
  });
}

module.exports = {
  initWebSocketServer,
  adminSetStockValue,
  getStockDetails,
  getStocksList,
  broadcastAlert
};
