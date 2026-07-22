# TradeMentor User Manual & Interface Guide

Welcome to TradeMentor. This guide explains how to navigate the system, build rule-based strategies, review alerts, talk to TradeMentor AI, and run the simulator.

---

## 📈 1. Navigating the Dashboard & Markets

When you log in, you will land on the **DashboardScreen**.
1. **Indices**: Track market health via Nifty 50 and Sensex tickers at the top.
2. **Portfolio Cards**: View your current paper portfolio value, investment costs, and net unrealized Profit & Loss (P&L) blinking in Green (profit) or Red (loss).
3. **Watchlists**: Tap tabs (e.g. "Core Stocks", "Crypto") to swipe between lists of securities. Tap the search icon to add new tickers instantly.

---

## ⚙️ 2. Designing Rule-Based Strategies

TradeMentor allows you to create custom conditions that analyze technical indicators and notify you when criteria are met.

### Step-by-Step Rule Creation:
1. Navigate to the **RuleBuilderScreen** by tapping "Create Rule" or the "+" sign in the alerts tab.
2. **Select Asset**: Type or pick the stock ticker (e.g. `TSLA`).
3. **Add Condition**:
   - **Indicator**: Choose from `Price`, `Volume`, `RSI`, or `MACD`.
   - **Relation**: Pick comparison triggers like `LESS_THAN`, `GREATER_THAN`, `CROSSES_ABOVE`, or `CROSSES_BELOW`.
   - **Threshold**: Enter numerical targets (e.g. enter `30` if using RSI Oversold).
4. **Trigger Operator**: If multiple conditions are added, select `AND` (all must match) or `OR` (any can match).
5. **Save Rule**: Give the rule a custom name (e.g. "Tesla RSI Buy Trigger") and save.

The rule will immediately start scanning against real-time feed ticks on the backend server.

---

## 🤖 3. Consulting TradeMentor AI

The chatbot helps you learn about market indicators and check portfolio health.

1. Navigate to the **ChatbotScreen** from the bottom bar.
2. Type commands or ask questions like:
   - *"What does a MACD bullish crossover mean?"*
   - *"Can you analyze my portfolio's risk profile?"*
   - *"Compare TSLA vs AAPL based on their P/E ratios."*
3. The chatbot will reply with clear, bulleted answers and suggest follow-up actions (e.g., creating a rule or showing chart analyses).

---

## 👑 4. The Administrator Dashboard & Simulator

If logged in with admin credentials, you gain access to the **AdminPanel**.

### Mock Market Control (Testing Rule Signals):
Testing alerts during closed market hours or waiting for real-world setups can take days. The admin module solves this with a **Mock Market Controller**:
1. Open the **MockMarketControlScreen** in the Admin tab.
2. Select a ticker (e.g. `AAPL`).
3. Slide the price control slider to spike or dump the value (e.g., force AAPL price from \$180 down to \$110, dragging the RSI to `20`).
4. Apply changes.
5. **Verification**: Within 2 seconds, you will receive a push notification header: *"Alert: Apple Inc. RSI Oversold Triggered!"*
6. Review the logs on the **AlertHistoryScreen** to confirm the rule-based engine operated correctly.
