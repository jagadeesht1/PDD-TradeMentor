const { expect } = require('chai');
const rulesEngineService = require('../src/services/rulesEngineService');

describe('Rules Engine Unit Tests', () => {
  beforeEach(() => {
    // Clear rules and alerts before each test for isolated testing
    rulesEngineService.clearRules();
    rulesEngineService.clearAlertHistory();
  });

  describe('Test Case UT-01: Rule Condition Validation (LESS_THAN)', () => {
    it('should trigger alert when stock price is lower than threshold', () => {
      // Setup a rule for testing
      const rule = {
        name: 'Test Price Drop Alert',
        ticker: 'TSLA',
        operator: 'AND',
        conditions: [
          { indicator: 'Price', comparison: 'LESS_THAN', thresholdValue: 150.00 }
        ],
        userId: 'test_user'
      };

      const registeredRule = rulesEngineService.addRule(rule);

      // Current mock stock tick
      const mockStockTick = {
        ticker: 'TSLA',
        companyName: 'Tesla Inc.',
        price: 145.20,
        rsi: 35.0,
        volume: 2400000,
        history: [148.0, 146.5, 145.2]
      };

      // Evaluate rules
      rulesEngineService.evaluateStockRules(mockStockTick);

      // Assert that alert is generated
      const alerts = rulesEngineService.getAlertHistory();
      expect(alerts).to.have.lengthOf(1);
      expect(alerts[0].ruleId).to.equal(registeredRule.id);
      expect(alerts[0].triggerPrice).to.equal(145.20);
      expect(alerts[0].message).to.contain('satisfied: Price (145.2) met condition LESS_THAN 150');

      // Cleanup rule
      rulesEngineService.deleteRule(registeredRule.id);
    });

    it('should NOT trigger alert when stock price is higher than threshold', () => {
      const rule = {
        name: 'Test Price Drop Alert',
        ticker: 'TSLA',
        operator: 'AND',
        conditions: [
          { indicator: 'Price', comparison: 'LESS_THAN', thresholdValue: 150.00 }
        ],
        userId: 'test_user'
      };

      const registeredRule = rulesEngineService.addRule(rule);

      const mockStockTick = {
        ticker: 'TSLA',
        companyName: 'Tesla Inc.',
        price: 152.50,
        rsi: 35.0,
        volume: 2400000,
        history: [148.0, 150.5, 152.5]
      };

      rulesEngineService.evaluateStockRules(mockStockTick);

      const alerts = rulesEngineService.getAlertHistory();
      expect(alerts).to.have.lengthOf(0);

      rulesEngineService.deleteRule(registeredRule.id);
    });
  });

  describe('Test Case UT-02: RSI Condition Validation', () => {
    it('should trigger alert when RSI is lower than threshold', () => {
      const rule = {
        name: 'Test RSI Oversold Alert',
        ticker: 'TSLA',
        operator: 'AND',
        conditions: [
          { indicator: 'RSI', comparison: 'LESS_THAN', thresholdValue: 30.00 }
        ],
        userId: 'test_user'
      };

      const registeredRule = rulesEngineService.addRule(rule);

      const mockStockTick = {
        ticker: 'TSLA',
        companyName: 'Tesla Inc.',
        price: 175.20,
        rsi: 28.4,
        volume: 2400000,
        history: [178.0, 177.0, 176.2, 175.2]
      };

      rulesEngineService.evaluateStockRules(mockStockTick);

      const alerts = rulesEngineService.getAlertHistory();
      expect(alerts).to.have.lengthOf(1);
      expect(alerts[0].ruleId).to.equal(registeredRule.id);
      expect(alerts[0].message).to.contain('RSI (28.4) met condition LESS_THAN 30');

      rulesEngineService.deleteRule(registeredRule.id);
    });

    it('should trigger alert with GREATER_THAN comparison', () => {
      const rule = {
        name: 'Test Price Breakout Alert',
        ticker: 'AAPL',
        operator: 'AND',
        conditions: [
          { indicator: 'Price', comparison: 'GREATER_THAN', thresholdValue: 190.00 }
        ],
        userId: 'test_user'
      };

      const registeredRule = rulesEngineService.addRule(rule);

      const mockStockTick = {
        ticker: 'AAPL',
        companyName: 'Apple Inc.',
        price: 195.50,
        rsi: 65.0,
        volume: 1500000,
        history: [188.0, 189.5, 195.5]
      };

      rulesEngineService.evaluateStockRules(mockStockTick);

      const alerts = rulesEngineService.getAlertHistory();
      expect(alerts).to.have.lengthOf(1);
      expect(alerts[0].ruleId).to.equal(registeredRule.id);
      expect(alerts[0].message).to.contain('Price (195.5) met condition GREATER_THAN 190');

      rulesEngineService.deleteRule(registeredRule.id);
    });
  });
});
