# API & WebSocket Integration Guide

This document catalogs the REST endpoints, WebSocket schemas, and Gemini AI message configurations for the TradeMentor server.

---

## 🌐 HTTP REST API Endpoints

The backend is built as a Node.js Express server running at `http://localhost:5000` (development) or a live hosted domain. All request and response structures use JSON.

### 1. Market Data & Feeds

#### Get Stock News
* **Endpoint**: `/api/stocks/news`
* **Method**: `GET`
* **Query Parameters**:
  - `ticker` (Optional): Filter news to a specific asset.
* **Response Status**: `200 OK`
* **Response Payload**:
```json
[
  {
    "id": "news_9012",
    "title": "Tech Stocks Rally Amid Lower Inflation Hopes",
    "summary": "Major indexes closed higher today as traders react to economic indicators...",
    "source": "Financial Chronicle",
    "ticker": "AAPL",
    "sentiment": "positive",
    "timestamp": "2026-06-15T18:30:00Z"
  }
]
```

---

### 2. Rule Validation & Simulation

#### Test Condition Set (Dry-run)
* **Endpoint**: `/api/rules/validate`
* **Method**: `POST`
* **Headers**: `Content-Type: application/json`
* **Request Payload**:
```json
{
  "ticker": "TSLA",
  "conditions": [
    {
      "indicator": "RSI",
      "period": 14,
      "comparison": "LESS_THAN",
      "thresholdValue": 35.0
    }
  ]
}
```
* **Response Status**: `200 OK`
* **Response Payload**:
```json
{
  "isValid": true,
  "currentIndicatorValue": 31.42,
  "isTriggeredNow": true,
  "calculatedAt": "2026-06-15T20:05:00Z"
}
```

---

### 3. TradeMentor AI Chatbot Bridge

#### Send Message to AI
* **Endpoint**: `/api/ai/chat`
* **Method**: `POST`
* **Headers**: `Content-Type: application/json`
* **Request Payload**:
```json
{
  "message": "Is AAPL oversold right now?",
  "portfolioSummary": {
    "totalInvested": 12500.0,
    "holdingsCount": 4
  },
  "history": [
    { "role": "user", "parts": "Hello" },
    { "role": "model", "parts": "Hello! I am TradeMentor AI, your financial assistant. How can I help you today?" }
  ]
}
```
* **Response Status**: `200 OK`
* **Response Payload**:
```json
{
  "response": "Based on current market data, AAPL is trading with an RSI of 28.5. An RSI below 30 indicates that an asset is technically oversold. However, look at MACD before acting...",
  "suggestedActions": [
    "View AAPL Charts",
    "Set alert for RSI Crossover"
  ]
}
```

---

## ⚡ WebSocket Feeds (Real-time Prices)

To sustain high-frequency UI updates without polling, clients connect to the Node.js server via WebSockets: `ws://localhost:5000/ws`.

### 1. Subscription Request
Once connected, the client subscribes to ticker channels:
```json
{
  "action": "subscribe",
  "tickers": ["AAPL", "TSLA", "MSFT"]
}
```

### 2. Tick Broadcast
The backend broadcasts price feeds every 2 seconds to subscribers:
```json
{
  "type": "tick",
  "ticker": "AAPL",
  "price": 182.45,
  "change": 1.25,
  "changePercent": 0.69,
  "volume": 245030,
  "rsi": 28.5,
  "macd": -0.42,
  "timestamp": "2026-06-15T20:08:42Z"
}
```

---

## 🤖 Gemini AI System Prompt Design

When a message is sent through the API bridge, the backend injects the following context prompt to constrain and guide the AI chatbot's persona:

```text
System Persona:
You are TradeMentor AI, an advanced virtual investment coach and technical analyst.
Your target is to educate, evaluate risks, and analyze charts.

Constraints:
1. NEVER offer definitive buy/sell instructions (no financial advice). Always frame recommendations as statistical rule outcomes.
2. If the user asks for specific stock calculations, perform technical estimates based on the metadata (price, RSI) provided in the request payload.
3. Keep answers concise, highly structured, and use Markdown format (bullets, bolding) to ensure readability on screens.
```
