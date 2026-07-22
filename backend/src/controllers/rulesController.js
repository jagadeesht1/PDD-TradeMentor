const rulesEngineService = require('../services/rulesEngineService');

function getRules(req, res) {
  return res.status(200).json(rulesEngineService.getActiveRules());
}

function createRule(req, res) {
  try {
    const { name, ticker, conditions, operator, userId } = req.body;
    if (!name || !ticker || !conditions || !conditions.length) {
      return res.status(400).json({ error: 'Missing required fields: name, ticker, or conditions' });
    }
    const rule = rulesEngineService.addRule({ name, ticker, conditions, operator: operator || 'AND', userId: userId || 'anonymous' });
    return res.status(201).json(rule);
  } catch (error) {
    return res.status(500).json({ error: 'Failed to create strategy rule' });
  }
}

function deleteRule(req, res) {
  const { id } = req.params;
  const success = rulesEngineService.deleteRule(id);
  if (success) {
    return res.status(200).json({ message: 'Rule successfully deleted' });
  }
  return res.status(404).json({ error: 'Rule not found' });
}

function toggleRule(req, res) {
  const { id } = req.params;
  const updatedRule = rulesEngineService.toggleRuleState(id);
  if (updatedRule) {
    return res.status(200).json(updatedRule);
  }
  return res.status(404).json({ error: 'Rule not found' });
}

function getAlerts(req, res) {
  return res.status(200).json(rulesEngineService.getAlertHistory());
}

function clearAlerts(req, res) {
  rulesEngineService.clearAlertHistory();
  return res.status(200).json({ message: 'Alert logs successfully cleared' });
}

function validateRuleDryRun(req, res) {
  const { ticker, conditions } = req.body;
  if (!ticker || !conditions) {
    return res.status(400).json({ error: 'Missing ticker or conditions for dry-run verification' });
  }
  // mock validate check
  const val = 28.5; // dummy calculated technical indicator value
  return res.status(200).json({
    isValid: true,
    currentIndicatorValue: val,
    isTriggeredNow: conditions.some(c => c.indicator === 'RSI' && val < c.thresholdValue),
    calculatedAt: new Date().toISOString()
  });
}

module.exports = {
  getRules,
  createRule,
  deleteRule,
  toggleRule,
  getAlerts,
  clearAlerts,
  validateRuleDryRun
};
