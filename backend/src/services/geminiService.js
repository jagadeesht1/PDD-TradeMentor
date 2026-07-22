// Gemini AI Connector service
const dns = require('dns');

async function handleAiConversation(userMessage, portfolioSummary = {}, chatHistory = []) {
  const apiKey = process.env.GEMINI_API_KEY;

  if (!apiKey || apiKey === 'your_gemini_api_key_here') {
    return getLocalResponse(userMessage, portfolioSummary);
  }

  // Attempt real API connection
  try {
    const fetch = (...args) => import('node-fetch').then(({default: fetch}) => fetch(...args));
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [
          {
            role: 'user',
            parts: [
              {
                text: `You are TradeMentor AI, an advanced fintech assistant.
                User Portfolio Context: ${JSON.stringify(portfolioSummary)}.
                User message: ${userMessage}.
                
                Respond in clean, brief Markdown formatting. Offer educational technical insights, but do NOT give direct buy/sell commands (provide no direct financial advice).`
              }
            ]
          }
        ]
      })
    });
    const result = await response.json();
    if (result.candidates && result.candidates[0].content.parts[0].text) {
      return {
        response: result.candidates[0].content.parts[0].text,
        suggestedActions: generateSuggestedActions(userMessage)
      };
    }
  } catch (err) {
    console.error('Gemini API call failed, falling back to local database engine.', err);
  }

  return getLocalResponse(userMessage, portfolioSummary);
}

function getLocalResponse(msg, portfolio) {
  const query = msg.toLowerCase();
  let text = '';
  let actions = [];

  if (query.includes('hello') || query.includes('hi') || query.includes('hey')) {
    text = `Hello! I am **TradeMentor AI**, your technical trading coach and portfolio analyzer. 

Here are some queries I can answer:
* **"Explain MACD indicator"**
* **"Evaluate my portfolio risk"**
* **"Compare Apple vs Tesla"**
* **"Explain RSI strategy"**

How can I help you today?`;
    actions = ['Explain RSI indicator', 'Evaluate my portfolio risk'];
  } else if (query.includes('rsi') || query.includes('relative strength index')) {
    text = `### Relative Strength Index (RSI) Overview

The **Relative Strength Index (RSI)** is a popular momentum oscillator used in technical analysis:
- **Range**: Scales from 0 to 100.
- **Oversold (< 30)**: Indicates the asset might be undervalued, representing a potential **Buy opportunity** when it crosses back above 30.
- **Overbought (> 70)**: Indicates the asset might be overvalued, representing a potential **Sell signal** when it crosses below 70.

**Suggested Strategy**: Configure a TradeMentor rule to track:
\`RSI CROSSES_BELOW 30\` for oversold detection, or \`RSI CROSSES_ABOVE 70\` for overbought alerts.`;
    actions = ['Set RSI Alert', 'Compare AAPL vs TSLA'];
  } else if (query.includes('macd') || query.includes('moving average convergence')) {
    text = `### MACD (Moving Average Convergence Divergence)

The **MACD** is a trend-following momentum indicator:
1. **MACD Line**: Difference between the 12-day and 26-day EMA.
2. **Signal Line**: 9-day EMA of the MACD Line.
3. **Histogram**: Visualizes the distance between the MACD and Signal lines.

**Signals**:
- **Bullish Crossover**: When the MACD line crosses **above** the Signal line (momentum turning positive).
- **Bearish Crossover**: When the MACD line crosses **below** the Signal line (momentum turning negative).`;
    actions = ['Explain RSI indicator', 'Build a MACD Rule'];
  } else if (query.includes('risk') || query.includes('portfolio')) {
    const value = portfolio.totalInvested || 45000.0;
    const holdings = portfolio.holdingsCount || 3;
    text = `### Portfolio Risk Evaluation

I have reviewed your active paper portfolio:
- **Invested Assets**: **${holdings} Holdings**
- **Estimated Capital**: **$${value.toLocaleString()}**

**Risk Breakdown**:
- **Asset Diversification**: High concentration in Tech Sector (AAPL, TSLA). We recommend allocating 20% to banking or FMCG sectors to hedge risk.
- **Rule Protection**: You currently have rules configured on some tickers. Enable stop-loss rule alerts to hedge against market downturns.`;
    actions = ['Diversify Portfolio', 'Set stop loss rule'];
  } else if (query.includes('compare') || query.includes('vs')) {
    text = `### Asset Comparison: Apple (AAPL) vs. Tesla (TSLA)

Here is a comparison of technical structures:

| Metric | Apple (AAPL) | Tesla (TSLA) |
| :--- | :--- | :--- |
| **Current Price** | $180.50 | $175.20 |
| **Relative Strength Index (RSI)** | 45.0 (Neutral) | 35.0 (Near Oversold) |
| **P/E Ratio** | 28.4 | 42.1 |
| **Volatility Risk** | Low-Medium | High |

**Analysis**:
- **AAPL** is in a stable consolidation phase with neutral momentum. Good for long-term value.
- **TSLA** is trading near oversold zones due to recent selling pressure, offering short-term bounce potential. Use alert thresholds carefully.`;
    actions = ['View AAPL charts', 'Create rule for TSLA'];
  } else {
    text = `I have analyzed your query about "${msg}". 

In trading, this represents a key analytical vector. Always combine technical oscillators (like RSI/MACD) with fundamental data (P/E ratio, dividend yield) to construct high-probability rule setups.

Would you like me to explain technical metrics or review your risk parameters?`;
    actions = ['Explain MACD indicator', 'Evaluate my portfolio risk'];
  }

  return { response: text, suggestedActions: actions };
}

function generateSuggestedActions(msg) {
  const query = msg.toLowerCase();
  if (query.includes('rsi')) return ['Create RSI rule', 'Explain MACD'];
  if (query.includes('macd')) return ['Create MACD rule', 'Compare AAPL vs TSLA'];
  if (query.includes('portfolio') || query.includes('risk')) return ['View holdings', 'Set Stop Loss rule'];
  return ['Explain technical indicators', 'Evaluate my portfolio risk'];
}

module.exports = {
  handleAiConversation
};
