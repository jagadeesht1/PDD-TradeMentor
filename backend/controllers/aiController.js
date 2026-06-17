const Stock = require('../../database/models/Stock');

// ─── Glossary data ───────────────────────────────────────────────────────────
const GLOSSARY = {
  'pe ratio': 'The Price-to-Earnings (P/E) ratio measures the share price relative to earnings per share. A high P/E could mean a stock is overvalued or has high growth potential; a low P/E suggests undervaluation or slower growth.',
  'stop loss': 'A Stop Loss is an automatic trigger order set to sell a security when it reaches a specific price limit, designed to limit investor losses on an adverse market move.',
  'rsi': 'The Relative Strength Index (RSI) is a technical momentum indicator ranging from 0 to 100. Traditionally, an RSI > 70 indicates a stock is overbought (overvalued), and < 30 indicates oversold (undervalued).',
  'macd': 'Moving Average Convergence Divergence (MACD) is a trend-following momentum indicator showing the relationship between two moving averages of a stock\'s price.',
  'portfolio': 'A portfolio is a grouping of financial assets such as stocks, bonds, and simulated cash. Rebalancing helps maintain your target risk profile as asset values change.',
  'unrealized pnl': 'Unrealized P&L (Paper Profit/Loss) represents the gains or losses in your open positions based on current market prices. It becomes a realized gain/loss only after you sell.',
  'realized pnl': 'Realized P&L is the actual profit or loss locked in after a stock position is closed (sold).',
  'limit order': 'A limit order is an order to buy or sell a stock with a restriction on the maximum price to be paid or minimum price to be received.',
  'market cap': 'Market Capitalization is the total market value of a company\'s outstanding shares of stock, calculated by multiplying shares outstanding by the current share price.'
};

// ─── AI Chat controller ───────────────────────────────────────────────────────
exports.handleChat = async (req, res) => {
  try {
    const { message, symbol, riskProfile } = req.body;
    if (!message) {
      return res.status(400).json({ error: 'Message content is required' });
    }

    const query = message.toLowerCase().trim();
    let reply = '';
    let data = null;

    // 1. INTENT: COMPARE STOCKS (e.g. "compare RELIANCE and TCS" or "TCS vs RELIANCE")
    if (query.includes('compare') || query.includes(' vs ') || query.includes(' versus ')) {
      const dbStocks = await Stock.find({ sector: { $ne: 'Index' } });
      const found = [];
      dbStocks.forEach(s => {
        if (query.includes(s.symbol.toLowerCase())) {
          found.push(s);
        }
      });

      if (found.length >= 2) {
        const s1 = found[0];
        const s2 = found[1];
        const pChange1 = s1.pChange >= 0 ? `+${s1.pChange}%` : `${s1.pChange}%`;
        const pChange2 = s2.pChange >= 0 ? `+${s2.pChange}%` : `${s2.pChange}%`;

        reply = `🔍 **TradeMentor AI Comparison Audit**:
Here is a side-by-side metric breakdown between **${s1.symbol}** and **${s2.symbol}** based on live market ticks:
- **Sector**: ${s1.symbol} is in *${s1.sector}* | ${s2.symbol} is in *${s2.sector}*
- **Current Price**: ₹${s1.currentPrice.toFixed(2)} vs ₹${s2.currentPrice.toFixed(2)}
- **Today's Change**: ${pChange1} (${s1.isGainer ? 'Bullish' : 'Bearish'}) vs ${pChange2} (${s2.isGainer ? 'Bullish' : 'Bearish'})

**AI Commentary**: ${s1.symbol} has a daily momentum of ${s1.pChange}%. ${s2.symbol} shows ${s2.pChange}%. If you are looking for sector diversification, ${s1.sector === s2.sector ? 'both belong to the same sector, consider spreading risk across other sectors.' : `diversifying between ${s1.sector} and ${s2.sector} is technically favorable.`}`;
        data = { stocks: found };
      } else {
        reply = `I can see you want to compare stocks, but I couldn't identify at least two valid seeded symbols. Try asking: *"Compare RELIANCE and TCS"* or *"TCS vs HDFCBANK"*.`;
      }
    }

    // 2. INTENT: TECHNICAL ANALYSIS OF A SPECIFIC STOCK (e.g. "technical analysis for INFY" or "is INFY a buy")
    else if (query.includes('technical') || query.includes('analysis') || query.includes('buy') || query.includes('sell') || query.includes('should i get')) {
      const dbStocks = await Stock.find({ sector: { $ne: 'Index' } });
      let stock = null;
      dbStocks.forEach(s => {
        if (query.includes(s.symbol.toLowerCase())) {
          stock = s;
        }
      });

      if (stock) {
        const momentum = stock.pChange;
        const trend = momentum >= 0 ? 'Bullish breakout' : 'Bearish correction';
        const recommendation = momentum > 1.0 ? 'Strong BUY (momentum)' : momentum < -1.0 ? 'BUY THE DIP opportunity' : 'HOLD (consolidation)';
        
        reply = `📈 **TradeMentor AI Technical Scan: ${stock.symbol}**
- **Live Price**: ₹${stock.currentPrice.toFixed(2)}
- **Daily Performance**: ${momentum >= 0 ? '+' : ''}${momentum}%
- **Identified Pattern**: *${trend}* in progress.
- **AI Recommendation**: **${recommendation}**. The stock is trading in the *${stock.sector}* sector with an exchange listing on *${stock.exchange}*.
- **Volume Signal**: Stable. Price is hovering near today\'s open of ₹${stock.openPrice.toFixed(2)}. Consider deploying a stop loss rule at ₹${(stock.currentPrice * 0.97).toFixed(2)} (3% stop loss).`;
        data = { stock };
      } else {
        reply = `I can perform a live technical scan on any seeded NSE stock. Please mention a valid symbol, for example: *"Technical analysis for RELIANCE"* or *"Is TCS a buy?"*`;
      }
    }

    // 3. INTENT: GENERAL MARKET TECHNICAL SCANNER (e.g. "scan the market" or "technical scanner")
    else if (query.includes('scan') || query.includes('scanner') || query.includes('breakout') || query.includes('bullish') || query.includes('bearish')) {
      const dbStocks = await Stock.find({ sector: { $ne: 'Index' } });
      const bullish = dbStocks.filter(s => s.pChange >= 0.7).map(s => s.symbol);
      const bearish = dbStocks.filter(s => s.pChange <= -0.7).map(s => s.symbol);

      reply = `📡 **TradeMentor AI Market Scanner Results**:
- **Bullish Momentum Breakouts**: ${bullish.length > 0 ? bullish.join(', ') : 'No strong breakouts found at this tick.'}
- **Bearish Corrections (Dip Buying Candidates)**: ${bearish.length > 0 ? bearish.join(', ') : 'No deep corrections found.'}

**Technical Outlook**: The overall sector trends show strong volumes in *IT* and *Automobile* segments. To optimize yields, set stop loss rules on bullish stocks or conditional buy alerts (Price <= target) on the corrections.`;
      data = { bullish, bearish };
    }

    // 4. INTENT: RISK / PORTFOLIO REBALANCING ADVICE (e.g. "suggest portfolio" or "how should I invest")
    else if (query.includes('portfolio') || query.includes('invest') || query.includes('risk') || query.includes('rebalance')) {
      const profile = riskProfile || 'moderate';
      let allocation = '';
      
      if (profile.toLowerCase() === 'high' || query.includes('high risk') || query.includes('aggressive')) {
        allocation = `- **Growth Equities (IT & Automobile)**: 60% (High beta growth: TCS, INFY, TATAMOTORS)
- **Energy & Industrials**: 20% (RELIANCE, LT)
- **Defensive (FMCG & Telecom)**: 10% (ITC, BHARTIARTL)
- **Liquidity / Wallet cash**: 10%`;
      } else if (profile.toLowerCase() === 'low' || query.includes('low risk') || query.includes('conservative')) {
        allocation = `- **Defensive Giants (FMCG)**: 50% (Low volatility: HINDUNILVR, ITC)
- **Financial Services**: 25% (HDFCBANK, ICICIBANK)
- **Market Indexes (NIFTY 50)**: 15%
- **Simulated Cash**: 10%`;
      } else {
        // Moderate default
        allocation = `- **Financial Services**: 30% (Stable core: HDFCBANK, AXISBANK)
- **Information Technology**: 30% (Growth: TCS, HCLTECH)
- **Energy & Construction**: 20% (RELIANCE, LT)
- **FMCG & Automobile**: 15% (ITC, MARUTI)
- **Wallet Cash Reserve**: 5%`;
      }

      reply = `💼 **TradeMentor AI Portfolio Allocator** (Risk Profile: **${profile.toUpperCase()}**):
Here is your optimized simulated asset distribution model based on current sector indexes:
${allocation}

**Rebalancing Recommendation**: Diversify across at least 4 sectors. Use rule-based alerts to enter positions when price drops below the moving averages.`;
      data = { allocation };
    }

    // 5. INTENT: FINANCIAL TERMINOLOGY GLOSSARY (e.g. "what is Stop Loss" or "PE ratio")
    else {
      let termFound = false;
      for (const [key, definition] of Object.entries(GLOSSARY)) {
        if (query.includes(key)) {
          reply = `📚 **TradeMentor Financial Dictionary**:
**${key.toUpperCase()}**: ${definition}`;
          termFound = true;
          break;
        }
      }

      // 6. FALLBACK RESPONSE
      if (!termFound) {
        reply = `Hello! I am your **TradeMentor AI Trading Assistant**. 🤖

I can help you monitor stock trends, scan the markets, and explain financial indicators. Try asking me:
- *"Is RELIANCE a buy right now?"*
- *"Compare TCS and INFY"*
- *"Run a market scanner"*
- *"How should I allocate a high-risk portfolio?"*
- *"What is a stop loss?"*`;
      }
    }

    res.json({ reply, data });
  } catch (err) {
    console.error('AI Chat Error:', err);
    res.status(500).json({ error: 'AI engine failed to process the request' });
  }
};

// ─── AI News Sentiment Scanner ────────────────────────────────────────────────
exports.getSentiment = async (req, res) => {
  try {
    const { symbol } = req.params;
    const stock = await Stock.findOne({ symbol: symbol.toUpperCase() });
    if (!stock) return res.status(404).json({ error: 'Stock not found' });

    // Generate mock sentiment metrics mathematically based on price changes
    const change = stock.pChange;
    const sentimentScore = Math.max(-1.0, Math.min(1.0, Number((change / 3).toFixed(2))));
    
    let sentimentLabel = 'NEUTRAL';
    let summary = '';
    if (sentimentScore >= 0.3) {
      sentimentLabel = 'BULLISH';
      summary = `Brokerages are positive on ${stock.symbol} following strong index volume. Expected technical resistance near ₹${(stock.currentPrice * 1.05).toFixed(2)}.`;
    } else if (sentimentScore <= -0.3) {
      sentimentLabel = 'BEARISH';
      summary = `${stock.symbol} sector reports short-term pressure. Technical support signals entry range around ₹${(stock.currentPrice * 0.95).toFixed(2)}.`;
    } else {
      sentimentLabel = 'NEUTRAL';
      summary = `${stock.symbol} is trading in range-bound consolidation. Investors await quarterly corporate earnings.`;
    }

    res.json({
      symbol: stock.symbol,
      price: stock.currentPrice,
      score: sentimentScore,
      label: sentimentLabel,
      summary,
      timestamp: new Date()
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
