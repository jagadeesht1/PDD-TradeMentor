const websocketService = require('../services/websocketService');

function getStocks(req, res) {
  return res.status(200).json(websocketService.getStocksList());
}

function getStockByTicker(req, res) {
  const { ticker } = req.params;
  const stock = websocketService.getStockDetails(ticker.toUpperCase());
  if (stock) {
    return res.status(200).json(stock);
  }
  return res.status(404).json({ error: 'Stock ticker not found' });
}

function updateStockPriceMock(req, res) {
  const { ticker, price, rsi, volume } = req.body;
  if (!ticker) {
    return res.status(400).json({ error: 'Ticker symbol is required' });
  }

  const success = websocketService.adminSetStockValue(ticker.toUpperCase(), { price, rsi, volume });
  if (success) {
    return res.status(200).json({ message: `Successfully updated mock parameters for ${ticker.toUpperCase()}` });
  }
  return res.status(404).json({ error: 'Stock ticker not found' });
}

function getStockNews(req, res) {
  const { ticker } = req.query;
  const mockNews = [
    {
      id: 'n1',
      title: 'Tesla Reports Delivery Numbers, Exceeds Analyst Target',
      summary: 'Tesla delivered over 490k vehicles this quarter, defying initial predictions and driving a tech momentum bounce...',
      source: 'Global Market Wire',
      ticker: 'TSLA',
      sentiment: 'positive',
      timestamp: new Date().toISOString()
    },
    {
      id: 'n2',
      title: 'Apple CEO Announces Next Gen AI Core Chips',
      summary: 'Apple Inc. announced its next generation chips optimized specifically for running AI calculations offline on consumer devices...',
      source: 'Tech Watch',
      ticker: 'AAPL',
      sentiment: 'positive',
      timestamp: new Date().toISOString()
    },
    {
      id: 'n3',
      title: 'Infosys Signs Major Cloud Multi-Year Digital Transformation Deal',
      summary: 'Infosys announced that it won a massive Cloud integration partnership with a major European logistics conglomerate...',
      source: 'Business Standard',
      ticker: 'INFY',
      sentiment: 'positive',
      timestamp: new Date().toISOString()
    },
    {
      id: 'n4',
      title: 'Microsoft Azure Expansion Boosts Enterprise Growth',
      summary: 'Enterprise demand for Microsoft AI integrations continues to drive Azure cloud expansion metrics higher...',
      source: 'Fintech Daily',
      ticker: 'MSFT',
      sentiment: 'positive',
      timestamp: new Date().toISOString()
    }
  ];

  if (ticker) {
    const filtered = mockNews.filter(n => n.ticker === ticker.toUpperCase());
    return res.status(200).json(filtered);
  }
  return res.status(200).json(mockNews);
}

module.exports = {
  getStocks,
  getStockByTicker,
  updateStockPriceMock,
  getStockNews
};
