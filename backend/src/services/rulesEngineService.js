const { v4: uuidv4 } = require('uuid');

// In-memory list of rules (pre-populated with mock rule triggers for testing)
let activeRules = [
  {
    id: 'rule_1',
    name: 'Tesla RSI Oversold Alert',
    ticker: 'TSLA',
    isActive: true,
    operator: 'AND',
    conditions: [
      { indicator: 'RSI', comparison: 'LESS_THAN', thresholdValue: 30 }
    ],
    userId: 'mock_user_123',
    createdAt: new Date().toISOString()
  },
  {
    id: 'rule_2',
    name: 'Apple Breakout Watch',
    ticker: 'AAPL',
    isActive: true,
    operator: 'AND',
    conditions: [
      { indicator: 'Price', comparison: 'GREATER_THAN', thresholdValue: 190 }
    ],
    userId: 'mock_user_123',
    createdAt: new Date().toISOString()
  },
  {
    id: 'rule_3',
    name: 'Infosys RSI oversold buy indicator',
    ticker: 'INFY',
    isActive: true,
    operator: 'AND',
    conditions: [
      { indicator: 'RSI', comparison: 'LESS_THAN', thresholdValue: 30 }
    ],
    userId: 'mock_user_123',
    createdAt: new Date().toISOString()
  }
];

// In-memory alert logs
let alertHistory = [];

function getActiveRules() {
  return activeRules;
}

function addRule(ruleData) {
  const newRule = {
    id: `rule_${uuidv4().substring(0, 8)}`,
    isActive: true,
    createdAt: new Date().toISOString(),
    ...ruleData
  };
  activeRules.push(newRule);
  console.log(`[RulesEngine] Added rule: ${newRule.name} for ticker ${newRule.ticker}`);
  return newRule;
}

function deleteRule(ruleId) {
  const initialLength = activeRules.length;
  activeRules = activeRules.filter(r => r.id !== ruleId);
  return activeRules.length < initialLength;
}

function toggleRuleState(ruleId) {
  const rule = activeRules.find(r => r.id === ruleId);
  if (rule) {
    rule.isActive = !rule.isActive;
    return rule;
  }
  return null;
}

function getAlertHistory() {
  return alertHistory;
}

function clearAlertHistory() {
  alertHistory = [];
}

// Evaluate rules against a stock tick update
function evaluateStockRules(stock) {
  const relevantRules = activeRules.filter(r => r.ticker === stock.ticker && r.isActive);

  relevantRules.forEach(rule => {
    let triggered = false;
    const triggerLogs = [];

    // Evaluate each condition
    const evaluations = rule.conditions.map(cond => {
      let isTrue = false;
      let currentValue = 0;

      if (cond.indicator === 'Price') {
        currentValue = stock.price;
        if (cond.comparison === 'LESS_THAN') isTrue = currentValue < cond.thresholdValue;
        if (cond.comparison === 'GREATER_THAN') isTrue = currentValue > cond.thresholdValue;
      } else if (cond.indicator === 'RSI') {
        currentValue = stock.rsi;
        if (cond.comparison === 'LESS_THAN') isTrue = currentValue < cond.thresholdValue;
        if (cond.comparison === 'GREATER_THAN') isTrue = currentValue > cond.thresholdValue;
      } else if (cond.indicator === 'Volume') {
        currentValue = stock.volume;
        if (cond.comparison === 'GREATER_THAN') isTrue = currentValue > cond.thresholdValue;
      }

      if (isTrue) {
        triggerLogs.push(`${cond.indicator} (${currentValue}) met condition ${cond.comparison} ${cond.thresholdValue}`);
      }
      return isTrue;
    });

    // Handle AND / OR operations
    if (rule.operator === 'OR') {
      triggered = evaluations.some(val => val === true);
    } else {
      triggered = evaluations.every(val => val === true);
    }

    if (triggered) {
      // Avoid duplicate alert logs if the same rule fires within 30 seconds
      const recentAlert = alertHistory.find(
        a => a.ruleId === rule.id && (new Date() - new Date(a.createdAt)) < 30000
      );
      if (!recentAlert) {
        const newAlert = {
          id: `alert_${uuidv4().substring(0, 8)}`,
          ruleId: rule.id,
          ruleName: rule.name,
          ticker: rule.ticker,
          triggerPrice: stock.price,
          message: `Strategy Alert fired: ${rule.name}. conditions satisfied: ${triggerLogs.join(', ')}`,
          readStatus: false,
          createdAt: new Date().toISOString()
        };
        alertHistory.unshift(newAlert);
        console.log(`[ALERT TRIGGERED] ${newAlert.message}`);
        
        // Broadcast the alert over websocket to connected clients
        try {
          const wsService = require('./websocketService');
          wsService.broadcastAlert(newAlert);
        } catch (e) {
          console.error('Failed to broadcast alert:', e);
        }
        
        // In product deployment, fire FCM notification here
      }
    }
  });
}

function clearRules() {
  activeRules = [];
}

module.exports = {
  getActiveRules,
  addRule,
  deleteRule,
  toggleRuleState,
  getAlertHistory,
  clearAlertHistory,
  evaluateStockRules,
  clearRules
};
