require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const jwt = require('jsonwebtoken');

const User      = require('../database/models/User');
const Stock     = require('../database/models/Stock');
const Alert     = require('../database/models/Alert');
const Trade     = require('../database/models/Trade');
const Portfolio = require('../database/models/Portfolio');
const aiController = require('./controllers/aiController');

const app = express();
const PORT      = process.env.PORT      || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/tradementor';
const JWT_SECRET = process.env.JWT_SECRET || 'super_secret_jwt_token_for_tradementor_2026';

// ─── Middleware ───────────────────────────────────────────────────────────────
app.use(express.json());
app.use(cors());

// Middleware to authenticate JWT
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.sendStatus(401);
  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
};

// ─── Seed Data ────────────────────────────────────────────────────────────────
const initialStocks = [
  // IT
  { symbol: 'TCS',         name: 'Tata Consultancy Services Ltd.',  exchange: 'NSE', currentPrice: 3480.00, openPrice: 3480.00, sector: 'IT' },
  { symbol: 'INFY',        name: 'Infosys Ltd.',                    exchange: 'NSE', currentPrice: 1475.00, openPrice: 1475.00, sector: 'IT' },
  { symbol: 'WIPRO',       name: 'Wipro Ltd.',                      exchange: 'NSE', currentPrice:  480.00, openPrice:  480.00, sector: 'IT' },
  { symbol: 'HCLTECH',     name: 'HCL Technologies Ltd.',           exchange: 'NSE', currentPrice: 1340.00, openPrice: 1340.00, sector: 'IT' },
  { symbol: 'TECHM',       name: 'Tech Mahindra Ltd.',              exchange: 'NSE', currentPrice: 1290.00, openPrice: 1290.00, sector: 'IT' },
  { symbol: 'MPHASIS',     name: 'Mphasis Ltd.',                    exchange: 'NSE', currentPrice: 2650.00, openPrice: 2650.00, sector: 'IT' },
  { symbol: 'PERSISTENT',  name: 'Persistent Systems Ltd.',         exchange: 'NSE', currentPrice: 4800.00, openPrice: 4800.00, sector: 'IT' },
  { symbol: 'COFORGE',     name: 'Coforge Ltd.',                    exchange: 'NSE', currentPrice: 7200.00, openPrice: 7200.00, sector: 'IT' },
  { symbol: 'LTIM',        name: 'LTIMindtree Ltd.',                exchange: 'NSE', currentPrice: 5100.00, openPrice: 5100.00, sector: 'IT' },

  // Financial Services
  { symbol: 'HDFCBANK',    name: 'HDFC Bank Ltd.',                  exchange: 'NSE', currentPrice: 1620.00, openPrice: 1620.00, sector: 'Financial Services' },
  { symbol: 'ICICIBANK',   name: 'ICICI Bank Ltd.',                 exchange: 'NSE', currentPrice:  980.00, openPrice:  980.00, sector: 'Financial Services' },
  { symbol: 'SBIN',        name: 'State Bank of India',             exchange: 'NSE', currentPrice:  590.00, openPrice:  590.00, sector: 'Financial Services' },
  { symbol: 'AXISBANK',    name: 'Axis Bank Ltd.',                  exchange: 'NSE', currentPrice: 1090.00, openPrice: 1090.00, sector: 'Financial Services' },
  { symbol: 'KOTAKBANK',   name: 'Kotak Mahindra Bank Ltd.',        exchange: 'NSE', currentPrice: 1780.00, openPrice: 1780.00, sector: 'Financial Services' },
  { symbol: 'INDUSINDBK',  name: 'IndusInd Bank Ltd.',              exchange: 'NSE', currentPrice:  960.00, openPrice:  960.00, sector: 'Financial Services' },
  { symbol: 'BAJFINANCE',  name: 'Bajaj Finance Ltd.',              exchange: 'NSE', currentPrice: 6800.00, openPrice: 6800.00, sector: 'Financial Services' },
  { symbol: 'FEDERALBNK',  name: 'Federal Bank Ltd.',               exchange: 'NSE', currentPrice:  160.00, openPrice:  160.00, sector: 'Financial Services' },
  { symbol: 'IDFCFIRSTB',  name: 'IDFC First Bank Ltd.',            exchange: 'NSE', currentPrice:   65.00, openPrice:   65.00, sector: 'Financial Services' },

  // Energy
  { symbol: 'RELIANCE',    name: 'Reliance Industries Ltd.',        exchange: 'NSE', currentPrice: 2450.00, openPrice: 2450.00, sector: 'Energy' },
  { symbol: 'NTPC',        name: 'NTPC Ltd.',                       exchange: 'NSE', currentPrice:  350.00, openPrice:  350.00, sector: 'Energy' },
  { symbol: 'POWERGRID',   name: 'Power Grid Corporation of India', exchange: 'NSE', currentPrice:  290.00, openPrice:  290.00, sector: 'Energy' },
  { symbol: 'ONGC',        name: 'Oil and Natural Gas Corp Ltd.',   exchange: 'NSE', currentPrice:  265.00, openPrice:  265.00, sector: 'Energy' },
  { symbol: 'COALINDIA',   name: 'Coal India Ltd.',                 exchange: 'NSE', currentPrice:  420.00, openPrice:  420.00, sector: 'Energy' },
  { symbol: 'ADANIGREEN',  name: 'Adani Green Energy Ltd.',         exchange: 'NSE', currentPrice: 1750.00, openPrice: 1750.00, sector: 'Energy' },

  // Automobile
  { symbol: 'TATAMOTORS',  name: 'Tata Motors Ltd.',                exchange: 'NSE', currentPrice:  910.00, openPrice:  910.00, sector: 'Automobile' },
  { symbol: 'MARUTI',      name: 'Maruti Suzuki India Ltd.',        exchange: 'NSE', currentPrice: 9800.00, openPrice: 9800.00, sector: 'Automobile' },
  { symbol: 'BAJAJ-AUTO',  name: 'Bajaj Auto Ltd.',                 exchange: 'NSE', currentPrice: 8900.00, openPrice: 8900.00, sector: 'Automobile' },
  { symbol: 'EICHERMOT',   name: 'Eicher Motors Ltd.',              exchange: 'NSE', currentPrice: 4200.00, openPrice: 4200.00, sector: 'Automobile' },
  { symbol: 'HEROMOTOCO',  name: 'Hero MotoCorp Ltd.',              exchange: 'NSE', currentPrice: 4700.00, openPrice: 4700.00, sector: 'Automobile' },
  { symbol: 'M&M',         name: 'Mahindra and Mahindra Ltd.',      exchange: 'NSE', currentPrice: 2100.00, openPrice: 2100.00, sector: 'Automobile' },

  // Pharma
  { symbol: 'SUNPHARMA',   name: 'Sun Pharmaceutical Ind Ltd.',    exchange: 'NSE', currentPrice: 1620.00, openPrice: 1620.00, sector: 'Pharma' },
  { symbol: 'DRREDDY',     name: 'Dr. Reddy\'s Laboratories Ltd.', exchange: 'NSE', currentPrice: 6200.00, openPrice: 6200.00, sector: 'Pharma' },
  { symbol: 'CIPLA',       name: 'Cipla Ltd.',                      exchange: 'NSE', currentPrice: 1480.00, openPrice: 1480.00, sector: 'Pharma' },
  { symbol: 'DIVISLAB',    name: 'Divi\'s Laboratories Ltd.',       exchange: 'NSE', currentPrice: 3900.00, openPrice: 3900.00, sector: 'Pharma' },
  { symbol: 'APOLLOHOSP',  name: 'Apollo Hospitals Enterprise Ltd.',exchange: 'NSE', currentPrice: 6800.00, openPrice: 6800.00, sector: 'Pharma' },

  // FMCG
  { symbol: 'ITC',         name: 'ITC Ltd.',                        exchange: 'NSE', currentPrice:  445.00, openPrice:  445.00, sector: 'FMCG' },
  { symbol: 'HINDUNILVR',  name: 'Hindustan Unilever Ltd.',         exchange: 'NSE', currentPrice: 2550.00, openPrice: 2550.00, sector: 'FMCG' },
  { symbol: 'NESTLEIND',   name: 'Nestle India Ltd.',               exchange: 'NSE', currentPrice:24000.00, openPrice:24000.00, sector: 'FMCG' },
  { symbol: 'BRITANNIA',   name: 'Britannia Industries Ltd.',       exchange: 'NSE', currentPrice: 4800.00, openPrice: 4800.00, sector: 'FMCG' },
  { symbol: 'DABUR',       name: 'Dabur India Ltd.',                exchange: 'NSE', currentPrice:  540.00, openPrice:  540.00, sector: 'FMCG' },
  { symbol: 'MARICO',      name: 'Marico Ltd.',                     exchange: 'NSE', currentPrice:  590.00, openPrice:  590.00, sector: 'FMCG' },

  // Metals
  { symbol: 'TATASTEEL',   name: 'Tata Steel Ltd.',                 exchange: 'NSE', currentPrice:  165.00, openPrice:  165.00, sector: 'Metals' },
  { symbol: 'HINDALCO',    name: 'Hindalco Industries Ltd.',        exchange: 'NSE', currentPrice:  640.00, openPrice:  640.00, sector: 'Metals' },
  { symbol: 'JSWSTEEL',    name: 'JSW Steel Ltd.',                  exchange: 'NSE', currentPrice:  840.00, openPrice:  840.00, sector: 'Metals' },
  { symbol: 'VEDL',        name: 'Vedanta Ltd.',                    exchange: 'NSE', currentPrice:  390.00, openPrice:  390.00, sector: 'Metals' },
  { symbol: 'NMDC',        name: 'NMDC Ltd.',                       exchange: 'NSE', currentPrice:  215.00, openPrice:  215.00, sector: 'Metals' },

  // Telecom
  { symbol: 'BHARTIARTL',  name: 'Bharti Airtel Ltd.',              exchange: 'NSE', currentPrice:  840.00, openPrice:  840.00, sector: 'Telecom' },

  // Construction / Infra
  { symbol: 'LT',          name: 'Larsen & Toubro Ltd.',            exchange: 'NSE', currentPrice: 2380.00, openPrice: 2380.00, sector: 'Construction' },
  { symbol: 'ADANIPORTS',  name: 'Adani Ports and SEZ Ltd.',        exchange: 'NSE', currentPrice: 1250.00, openPrice: 1250.00, sector: 'Construction' },
  { symbol: 'ULTRACEMCO',  name: 'UltraTech Cement Ltd.',           exchange: 'NSE', currentPrice: 9700.00, openPrice: 9700.00, sector: 'Construction' },
  { symbol: 'GRASIM',      name: 'Grasim Industries Ltd.',          exchange: 'NSE', currentPrice: 2400.00, openPrice: 2400.00, sector: 'Construction' },
  { symbol: 'ACC',         name: 'ACC Ltd.',                        exchange: 'NSE', currentPrice: 2100.00, openPrice: 2100.00, sector: 'Construction' },
];

const initialIndices = [
  { symbol: 'NIFTY 50',    name: 'Nifty 50 Index',             exchange: 'NSE', currentPrice: 22400.00, openPrice: 22400.00, sector: 'Index' },
  { symbol: 'SENSEX',      name: 'Sensex Index',               exchange: 'BSE', currentPrice: 73700.00, openPrice: 73700.00, sector: 'Index' },
  { symbol: 'NIFTY BANK',  name: 'Nifty Bank Index',           exchange: 'NSE', currentPrice: 48200.00, openPrice: 48200.00, sector: 'Index' },
  { symbol: 'NIFTY IT',    name: 'Nifty IT Index',             exchange: 'NSE', currentPrice: 33500.00, openPrice: 33500.00, sector: 'Index' },
  { symbol: 'NIFTY AUTO',  name: 'Nifty Auto Index',           exchange: 'NSE', currentPrice: 21800.00, openPrice: 21800.00, sector: 'Index' },
  { symbol: 'NIFTY PHARMA',name: 'Nifty Pharma Index',         exchange: 'NSE', currentPrice: 19600.00, openPrice: 19600.00, sector: 'Index' },
];


// ─── Hybrid Data Access Layer (Mongoose + In-Memory Fallback) ───────────────
const memoryStore = {
  stocks: [],
  users: [],
  portfolios: [],
  alerts: [],
  trades: []
};

// Generate MongoDB-like 24-char ObjectId
function generateObjectId() {
  return Math.floor(Date.now() / 1000).toString(16).padStart(8, '0') + 'xxxxxxxxxxxxxxxx'.replace(/[x]/g, () => (Math.random() * 16 | 0).toString(16));
}

const DB = {
  isMongo() { return mongoose.connection.readyState === 1; },

  async countStocks() {
    return this.isMongo() ? await Stock.countDocuments() : memoryStore.stocks.length;
  },

  async insertStocks(items) {
    if (this.isMongo()) {
      await Stock.insertMany(items);
    } else {
      items.forEach(i => {
        memoryStore.stocks.push({
          _id: generateObjectId(),
          ...i,
          pChange: 0,
          isGainer: false,
          lastUpdated: new Date(),
          async save() { return this; }
        });
      });
    }
  },

  async getStocks(filter = {}) {
    if (this.isMongo()) return await Stock.find(filter).sort({ symbol: 1 });
    let res = memoryStore.stocks;
    if (filter.sector && filter.sector.$ne) res = res.filter(s => s.sector !== filter.sector.$ne);
    if (filter.sector && typeof filter.sector === 'string') res = res.filter(s => s.sector === filter.sector);
    return res;
  },

  async getStock(filter) {
    if (this.isMongo()) return await Stock.findOne(filter);
    if (filter.symbol) return memoryStore.stocks.find(s => s.symbol === filter.symbol.toUpperCase());
    return null;
  },

  async countUsers() {
    return this.isMongo() ? await User.countDocuments() : memoryStore.users.length;
  },

  async createUser(userData) {
    if (this.isMongo()) {
      const u = new User(userData);
      await u.save();
      return u;
    } else {
      const bcrypt = require('bcryptjs');
      const salt = await bcrypt.genSalt(10);
      const hashedPassword = await bcrypt.hash(userData.password, salt);
      const userObj = {
        _id: generateObjectId(),
        name: userData.name,
        email: userData.email.toLowerCase(),
        password: hashedPassword,
        walletBalance: userData.walletBalance || 100000.00,
        async comparePassword(candidate) {
          return bcrypt.compare(candidate, this.password);
        },
        async save() { return this; }
      };
      memoryStore.users.push(userObj);
      return userObj;
    }
  },

  async getUser(filter) {
    if (this.isMongo()) return await User.findOne(filter);
    if (filter.email) return memoryStore.users.find(u => u.email === filter.email.toLowerCase());
    if (filter._id) return memoryStore.users.find(u => String(u._id) === String(filter._id));
    return null;
  },

  async createPortfolio(pData) {
    if (this.isMongo()) return await Portfolio.create(pData);
    const pObj = {
      _id: generateObjectId(),
      userId: pData.userId,
      holdings: pData.holdings || [],
      totalRealizedPnL: 0,
      findHolding(symbol) {
        return this.holdings.findIndex(h => h.symbol === symbol.toUpperCase());
      },
      markModified() {},
      async save() { return this; }
    };
    memoryStore.portfolios.push(pObj);
    return pObj;
  },

  async getPortfolio(userId) {
    if (this.isMongo()) return await Portfolio.findOne({ userId });
    let p = memoryStore.portfolios.find(pt => String(pt.userId) === String(userId));
    if (!p) p = await this.createPortfolio({ userId, holdings: [] });
    return p;
  },

  async createAlert(aData) {
    if (this.isMongo()) return await Alert.create(aData);
    const alertObj = {
      _id: generateObjectId(),
      userId: aData.userId,
      symbol: aData.symbol.toUpperCase(),
      targetPrice: Number(aData.targetPrice),
      criteria: aData.criteria,
      isTriggered: aData.isTriggered || false,
      createdAt: new Date(),
      async save() { return this; }
    };
    memoryStore.alerts.push(alertObj);
    return alertObj;
  },

  async getAlerts(filter) {
    if (this.isMongo()) return await Alert.find(filter).sort({ createdAt: -1 });
    let res = memoryStore.alerts;
    if (filter.userId) res = res.filter(a => String(a.userId) === String(filter.userId));
    if (filter.isTriggered !== undefined) res = res.filter(a => a.isTriggered === filter.isTriggered);
    return res;
  },

  async deleteAlert(alertId) {
    if (this.isMongo()) return await Alert.findByIdAndDelete(alertId);
    const idx = memoryStore.alerts.findIndex(a => String(a._id) === String(alertId));
    if (idx >= 0) return memoryStore.alerts.splice(idx, 1)[0];
    return null;
  },

  async createTrade(tData) {
    if (this.isMongo()) {
      const t = new Trade(tData);
      await t.save();
      return t;
    } else {
      const tradeObj = {
        _id: generateObjectId(),
        ...tData,
        createdAt: new Date(),
        async save() { return this; }
      };
      memoryStore.trades.push(tradeObj);
      return tradeObj;
    }
  },

  async getTrades(userId, skip = 0, limit = 50) {
    if (this.isMongo()) {
      const [trades, total] = await Promise.all([
        Trade.find({ userId }).sort({ createdAt: -1 }).skip(skip).limit(limit),
        Trade.countDocuments({ userId })
      ]);
      return { trades, total };
    } else {
      const userTrades = memoryStore.trades.filter(t => String(t.userId) === String(userId));
      const trades = userTrades.slice().reverse().slice(skip, skip + limit);
      return { trades, total: userTrades.length };
    }
  }
};

// ─── Database Seeder ──────────────────────────────────────────────────────────
async function seedDatabase() {
  try {
    const stockCount = await DB.countStocks();
    if (stockCount === 0) {
      console.log('Seeding initial stock list and index tickers...');
      await DB.insertStocks([...initialStocks, ...initialIndices]);
      console.log('Stock and Index records successfully seeded!');
    }

    const userCount = await DB.countUsers();
    if (userCount === 0) {
      console.log('Seeding default mock user for virtual trading...');
      const defaultUser = await DB.createUser({
        name: 'Demo Investor',
        email: 'demo@tradementor.com',
        password: 'password123',
        walletBalance: 100000.00
      });
      console.log(`Default user created: ${defaultUser.email} | ID: ${defaultUser._id}`);

      // Seed initial empty portfolio
      await DB.createPortfolio({ userId: defaultUser._id, holdings: [] });
      console.log('Empty portfolio initialized for default user');

      // Seed a sample alert
      await DB.createAlert({
        userId: defaultUser._id,
        symbol: 'RELIANCE',
        targetPrice: 2470.00,
        isTriggered: false,
        criteria: 'GREATER_THAN'
      });
      console.log('Default test alert seeded for RELIANCE @ ₹2470.00');
    }
  } catch (error) {
    console.error('Error seeding database:', error);
  }
}

// ─── Mock Market Engine ───────────────────────────────────────────────────────
// Runs every 5 seconds, fluctuates prices randomly between -1.5% and +1.5%
async function runMarketEngine() {
  try {
    const stocks = await DB.getStocks();
    if (stocks.length === 0) return;

    for (const stock of stocks) {
      const pctChange  = (Math.random() * 3) - 1.5;
      const multiplier = 1 + (pctChange / 100);
      const newPrice   = Number((stock.currentPrice * multiplier).toFixed(2));
      const pChange    = Number((((newPrice - stock.openPrice) / stock.openPrice) * 100).toFixed(2));

      stock.currentPrice = newPrice;
      stock.pChange      = pChange;
      stock.isGainer     = newPrice >= stock.openPrice;
      stock.lastUpdated  = new Date();
      await stock.save();
    }

    // Evaluate pending alert rules
    const pendingAlerts = await DB.getAlerts({ isTriggered: false });
    for (const alert of pendingAlerts) {
      const stock = await DB.getStock({ symbol: alert.symbol });
      if (!stock) continue;

      let trigger = false;
      if (alert.criteria === 'GREATER_THAN' && stock.currentPrice >= alert.targetPrice) trigger = true;
      if (alert.criteria === 'LESS_THAN'    && stock.currentPrice <= alert.targetPrice) trigger = true;
      if (alert.criteria === 'STOP_LOSS'    && stock.currentPrice <= alert.targetPrice) trigger = true;

      if (trigger) {
        alert.isTriggered  = true;
        alert.triggeredAt  = new Date();
        await alert.save();
        console.log(`[ALERT FIRED] ${alert.symbol} | ${alert.criteria} | Target: ₹${alert.targetPrice} | Now: ₹${stock.currentPrice}`);
      }
    }
  } catch (error) {
    console.error('Market engine error:', error);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// API ROUTES
// ═══════════════════════════════════════════════════════════════════════════════

// ── Auth ──────────────────────────────────────────────────────────────────────
// POST /api/auth/register — Create new user account
app.post('/api/auth/register', async (req, res) => {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({ error: 'Name, email and password are required' });
    }
    if (password.length < 6) {
      return res.status(400).json({ error: 'Password must be at least 6 characters' });
    }
    const existing = await DB.getUser({ email: email.toLowerCase() });
    if (existing) {
      return res.status(409).json({ error: 'An account with this email already exists' });
    }
    const user = await DB.createUser({ name, email, password, walletBalance: 100000.00 });
    await DB.createPortfolio({ userId: user._id, holdings: [] });
    const token = jwt.sign({ userId: user._id, email: user.email }, JWT_SECRET, { expiresIn: '30d' });
    console.log(`[AUTH] New user registered: ${user.email} | ID: ${user._id}`);
    res.status(201).json({
      message: 'Account created successfully',
      token,
      userId: user._id,
      name: user.name,
      email: user.email,
      walletBalance: user.walletBalance
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/auth/login — Authenticate and return JWT
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }
    const user = await DB.getUser({ email: email.toLowerCase() });
    if (!user) {
      return res.status(401).json({ error: 'No account found with this email address' });
    }
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Incorrect password. Please try again.' });
    }
    const token = jwt.sign({ userId: user._id, email: user.email }, JWT_SECRET, { expiresIn: '30d' });
    console.log(`[AUTH] Login: ${user.email}`);
    res.json({
      message: 'Login successful',
      token,
      userId: user._id,
      name: user.name,
      email: user.email,
      walletBalance: user.walletBalance
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/auth/google — Authenticate via Simulated Google Sign-In
app.post('/api/auth/google', async (req, res) => {
  try {
    const { email, name } = req.body;
    if (!email || !name) {
      return res.status(400).json({ error: 'Email and name are required for Google Auth' });
    }
    
    let user = await DB.getUser({ email: email.toLowerCase() });
    
    if (!user) {
      const randomPassword = Math.random().toString(36).slice(-10) + 'A1!';
      user = await DB.createUser({ name, email: email.toLowerCase(), password: randomPassword, walletBalance: 100000.00 });
      await DB.createPortfolio({ userId: user._id, holdings: [] });
      console.log(`[AUTH] New user registered via Google: ${user.email} | ID: ${user._id}`);
    } else {
      console.log(`[AUTH] Login via Google: ${user.email}`);
    }
    
    const token = jwt.sign({ userId: user._id, email: user.email }, JWT_SECRET, { expiresIn: '30d' });
    res.json({
      message: 'Google login successful',
      token,
      userId: user._id,
      name: user.name,
      email: user.email,
      walletBalance: user.walletBalance
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Stocks ────────────────────────────────────────────────────────────────────
// GET /api/stocks — All equities (no indices)
app.get('/api/stocks', async (req, res) => {
  try {
    const stocks = await DB.getStocks({ sector: { $ne: 'Index' } });
    res.json(stocks);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/stocks/:symbol — Single stock detail
app.get('/api/stocks/:symbol', async (req, res) => {
  try {
    const stock = await DB.getStock({ symbol: req.params.symbol.toUpperCase() });
    if (!stock) return res.status(404).json({ error: 'Stock not found' });
    res.json(stock);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/indices — Market indices only
app.get('/api/indices', async (req, res) => {
  try {
    const indices = await DB.getStocks({ sector: 'Index' });
    res.json(indices);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Users ─────────────────────────────────────────────────────────────────────
// GET /api/users/default — Fetch default mock user
app.get('/api/users/default', async (req, res) => {
  try {
    const user = await DB.getUser({ email: 'demo@tradementor.com' });
    if (!user) return res.status(404).json({ error: 'Default user not seeded yet' });
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Alerts ────────────────────────────────────────────────────────────────────
// POST /api/alerts — Create a rule-based alert
app.post('/api/alerts', async (req, res) => {
  try {
    const { userId, symbol, targetPrice, criteria } = req.body;
    if (!userId || !symbol || !targetPrice || !criteria) {
      return res.status(400).json({ error: 'Missing required parameters' });
    }
    const newAlert = await DB.createAlert({
      userId,
      symbol: symbol.toUpperCase(),
      targetPrice: Number(targetPrice),
      criteria,
      isTriggered: false
    });
    res.status(201).json(newAlert);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/alerts/:userId — Fetch user alerts
app.get('/api/alerts/:userId', async (req, res) => {
  try {
    const alerts = await DB.getAlerts({ userId: req.params.userId });
    res.json(alerts);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/alerts/:alertId — Delete an alert rule
app.delete('/api/alerts/:alertId', async (req, res) => {
  try {
    const deleted = await DB.deleteAlert(req.params.alertId);
    if (!deleted) return res.status(404).json({ error: 'Alert not found' });
    res.json({ message: 'Alert deleted successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Paper Trading ─────────────────────────────────────────────────────────────
// POST /api/trade — Execute BUY or SELL simulated trade
app.post('/api/trade', async (req, res) => {
  const { userId, symbol, type, quantity } = req.body;
  if (!userId || !symbol || !type || !quantity) {
    return res.status(400).json({ error: 'Missing required trade parameters' });
  }

  const qty = parseInt(quantity, 10);
  if (isNaN(qty) || qty < 1) {
    return res.status(400).json({ error: 'Quantity must be a positive integer' });
  }

  const tradeType = type.toUpperCase();
  if (!['BUY', 'SELL'].includes(tradeType)) {
    return res.status(400).json({ error: 'Type must be BUY or SELL' });
  }

  try {
    const stock = await DB.getStock({ symbol: symbol.toUpperCase() });
    if (!stock) return res.status(404).json({ error: `Stock ${symbol} not found` });

    const user = await DB.getUser({ _id: userId });
    if (!user) return res.status(404).json({ error: 'User not found' });

    let portfolio = await DB.getPortfolio(userId);
    if (!portfolio) portfolio = await DB.createPortfolio({ userId, holdings: [] });

    const tradeValue = Number((qty * stock.currentPrice).toFixed(2));
    const holdingIdx = portfolio.findHolding(stock.symbol);
    let realizedPnL = null;

    if (tradeType === 'BUY') {
      if (user.walletBalance < tradeValue) {
        return res.status(400).json({ error: `Insufficient wallet balance. Need ₹${tradeValue.toFixed(2)}, have ₹${user.walletBalance.toFixed(2)}` });
      }
      user.walletBalance = Number((user.walletBalance - tradeValue).toFixed(2));

      if (holdingIdx >= 0) {
        const h = portfolio.holdings[holdingIdx];
        const newTotalInvested = Number((h.totalInvested + tradeValue).toFixed(2));
        const newQty           = h.quantity + qty;
        portfolio.holdings[holdingIdx].quantity         = newQty;
        portfolio.holdings[holdingIdx].totalInvested    = newTotalInvested;
        portfolio.holdings[holdingIdx].averageBuyPrice  = Number((newTotalInvested / newQty).toFixed(2));
      } else {
        portfolio.holdings.push({
          symbol:          stock.symbol,
          stockName:       stock.name,
          exchange:        stock.exchange,
          quantity:        qty,
          averageBuyPrice: stock.currentPrice,
          totalInvested:   tradeValue
        });
      }
    }

    if (tradeType === 'SELL') {
      if (holdingIdx < 0 || portfolio.holdings[holdingIdx].quantity < qty) {
        const heldQty = holdingIdx >= 0 ? portfolio.holdings[holdingIdx].quantity : 0;
        return res.status(400).json({ error: `Cannot sell ${qty} shares. You only hold ${heldQty} of ${stock.symbol}` });
      }

      const h          = portfolio.holdings[holdingIdx];
      const costBasis  = Number((h.averageBuyPrice * qty).toFixed(2));
      realizedPnL      = Number((tradeValue - costBasis).toFixed(2));

      user.walletBalance               = Number((user.walletBalance + tradeValue).toFixed(2));
      portfolio.totalRealizedPnL       = Number((portfolio.totalRealizedPnL + realizedPnL).toFixed(2));

      const newQty = h.quantity - qty;
      if (newQty === 0) {
        portfolio.holdings.splice(holdingIdx, 1);
      } else {
        portfolio.holdings[holdingIdx].quantity      = newQty;
        portfolio.holdings[holdingIdx].totalInvested = Number((h.averageBuyPrice * newQty).toFixed(2));
      }
    }

    if (typeof portfolio.markModified === 'function') portfolio.markModified('holdings');
    await portfolio.save();
    await user.save();

    const trade = await DB.createTrade({
      userId,
      symbol:      stock.symbol,
      stockName:   stock.name,
      exchange:    stock.exchange,
      type:        tradeType,
      quantity:    qty,
      price:       stock.currentPrice,
      totalValue:  tradeValue,
      realizedPnL
    });

    console.log(`[TRADE] ${tradeType} | ${qty}x ${symbol} @ ₹${trade.price} | User balance: ₹${user.walletBalance}`);
    return res.status(201).json({
      message: `${tradeType} order executed successfully`,
      trade,
      newBalance: user.walletBalance,
      realizedPnL
    });
  } catch (err) {
    console.error('Trade execution error:', err);
    return res.status(500).json({ error: err.message });
  }
});

// ── Portfolio ─────────────────────────────────────────────────────────────────
// GET /api/portfolio/:userId — Holdings with live P&L
app.get('/api/portfolio/:userId', async (req, res) => {
  try {
    const portfolio = await DB.getPortfolio(req.params.userId);
    if (!portfolio) return res.status(404).json({ error: 'Portfolio not found for this user' });

    const enrichedHoldings = await Promise.all(
      portfolio.holdings.map(async (h) => {
        const stock = await DB.getStock({ symbol: h.symbol });
        const currentPrice   = stock ? stock.currentPrice : h.averageBuyPrice;
        const currentValue   = Number((currentPrice * h.quantity).toFixed(2));
        const unrealizedPnL  = Number((currentValue - h.totalInvested).toFixed(2));
        const pnlPercent     = Number(((unrealizedPnL / h.totalInvested) * 100).toFixed(2));

        return {
          symbol:         h.symbol,
          stockName:      h.stockName,
          exchange:       h.exchange,
          quantity:       h.quantity,
          averageBuyPrice:h.averageBuyPrice,
          totalInvested:  h.totalInvested,
          currentPrice,
          currentValue,
          unrealizedPnL,
          pnlPercent
        };
      })
    );

    const totalInvested     = enrichedHoldings.reduce((s, h) => s + h.totalInvested, 0);
    const totalCurrentValue = enrichedHoldings.reduce((s, h) => s + h.currentValue, 0);
    const totalUnrealized   = Number((totalCurrentValue - totalInvested).toFixed(2));

    res.json({
      holdings:          enrichedHoldings,
      totalInvested:     Number(totalInvested.toFixed(2)),
      totalCurrentValue: Number(totalCurrentValue.toFixed(2)),
      totalUnrealized,
      totalRealizedPnL:  portfolio.totalRealizedPnL
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Trade History ─────────────────────────────────────────────────────────────
// GET /api/trades/:userId — All trade records for user (paginated)
app.get('/api/trades/:userId', async (req, res) => {
  try {
    const page  = parseInt(req.query.page  || '1',  10);
    const limit = parseInt(req.query.limit || '20', 10);
    const skip  = (page - 1) * limit;

    const { trades, total } = await DB.getTrades(req.params.userId, skip, limit);
    res.json({ trades, total, page, totalPages: Math.ceil(total / limit) || 1 });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── AI Assistant ──────────────────────────────────────────────────────────────
app.post('/api/ai/chat', aiController.handleChat);
app.get('/api/ai/sentiment/:symbol', aiController.getSentiment);

// ── Friendly API Homepage ───────────────────────────────────────────────────
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
      <head>
        <title>TradeMentor API Server</title>
        <style>
          body { background-color: #0B121E; color: white; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
          .card { background-color: #141F32; border: 1px solid rgba(255, 255, 255, 0.05); padding: 40px; border-radius: 24px; text-align: center; box-shadow: 0 20px 40px rgba(0,0,0,0.4); max-width: 420px; }
          .logo { height: 60px; width: 60px; background-color: rgba(0, 208, 156, 0.1); border: 1px solid rgba(0, 208, 156, 0.2); border-radius: 50%; display: flex; align-items: center; justify-content: center; margin: 0 auto 20px auto; }
          .logo-icon { width: 30px; height: 30px; border-left: 4px solid #00D09C; border-bottom: 4px solid #00D09C; transform: rotate(-45deg); margin-left: 4px; margin-bottom: 4px; }
          h1 { color: white; font-size: 22px; margin: 0 0 10px 0; font-weight: 800; }
          p { color: #a0aec0; font-size: 13px; line-height: 1.6; margin: 0 0 24px 0; }
          .badge { background-color: rgba(0, 208, 156, 0.12); color: #00D09C; border: 1px solid rgba(0, 208, 156, 0.2); padding: 6px 16px; border-radius: 20px; font-size: 11px; font-weight: bold; display: inline-block; letter-spacing: 0.5px; }
        </style>
      </head>
      <body>
        <div class="card">
          <div class="logo">
            <div class="logo-icon"></div>
          </div>
          <h1>TradeMentor API</h1>
          <p>The virtual Indian real-time equities database and AI advisor engine is online, database seeded, and responding healthy.</p>
          <span class="badge">STATUS: LIVE & CONNECTED</span>
        </div>
      </body>
    </html>
  `);
});

// ── Health Check ──────────────────────────────────────────────────────────────
app.get('/api/health', (_, res) => {
  res.json({
    status:    'OK',
    service:   'TradeMentor API',
    timestamp: new Date().toISOString(),
    mongoState: mongoose.connection.readyState === 1 ? 'Connected' : 'Disconnected'
  });
});

// ═══════════════════════════════════════════════════════════════════════════════
// BOOT & DATABASE CONNECTION WITH IN-MEMORY FALLBACK
// ═══════════════════════════════════════════════════════════════════════════════
mongoose.connection.on('connected', () => {
  console.log('MongoDB connection established successfully.');
});

mongoose.connection.on('error', (err) => {
  console.error('MongoDB connection error:', err.message);
});

async function connectDBWithRetry() {
  // Try external / local MongoDB instance
  try {
    console.log(`Connecting to local MongoDB at ${MONGO_URI}...`);
    await mongoose.connect(MONGO_URI, { serverSelectionTimeoutMS: 2000 });
    console.log('Successfully connected to local MongoDB database!');
    return true;
  } catch (err) {
    console.warn(`Local MongoDB not running on ${MONGO_URI}: ${err.message}`);
    console.log('⚡ Initialized In-Memory Database Mode for fast, zero-dependency execution.');
    return false;
  }
}

async function startServer() {
  const dbConnected = await connectDBWithRetry();
  
  try {
    await seedDatabase();
  } catch (seedErr) {
    console.warn('Seeding notice:', seedErr.message);
  }

  setInterval(runMarketEngine, 5000);
  console.log('Background Mock Market Engine initialized (5s refresh rate)');

  app.listen(PORT, () => {
    console.log(`===============================================`);
    console.log(` TradeMentor API server running on http://localhost:${PORT}`);
    console.log(` Health check endpoint: http://localhost:${PORT}/api/health`);
    console.log(` DB Status: ${mongoose.connection.readyState === 1 ? 'CONNECTED' : 'IN-MEMORY MODE'}`);
    console.log(`===============================================`);
  });
}

startServer();



