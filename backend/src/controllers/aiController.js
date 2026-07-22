const geminiService = require('../services/geminiService');

async function handleChat(req, res) {
  try {
    const { message, portfolioSummary, history } = req.body;
    if (!message) {
      return res.status(400).json({ error: 'Message field is required' });
    }

    const aiResult = await geminiService.handleAiConversation(message, portfolioSummary, history);
    return res.status(200).json(aiResult);
  } catch (error) {
    console.error('Chat controller error:', error);
    return res.status(500).json({ error: 'Failed to process AI chat request' });
  }
}

module.exports = {
  handleChat
};
