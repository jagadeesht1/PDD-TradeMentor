const express = require('express');
const router = express.Router();

const stocksController = require('../controllers/stocksController');
const rulesController = require('../controllers/rulesController');
const aiController = require('../controllers/aiController');

// Stocks endpoints
router.get('/stocks', stocksController.getStocks);
router.get('/stocks/news', stocksController.getStockNews);
router.get('/stocks/:ticker', stocksController.getStockByTicker);
router.post('/stocks/mock-update', stocksController.updateStockPriceMock);

// Rules endpoints
router.get('/rules', rulesController.getRules);
router.post('/rules', rulesController.createRule);
router.delete('/rules/:id', rulesController.deleteRule);
router.post('/rules/:id/toggle', rulesController.toggleRule);
router.post('/rules/validate', rulesController.validateRuleDryRun);

// Alerts endpoints
router.get('/alerts', rulesController.getAlerts);
router.post('/alerts/clear', rulesController.clearAlerts);

// AI Chatbot endpoint
router.post('/ai/chat', aiController.handleChat);

module.exports = router;
