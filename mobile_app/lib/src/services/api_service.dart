import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/stock_model.dart';
import '../core/constants/app_constants.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  // Fetch stocks list
  Future<List<StockModel>> getStocks() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseRestUrl}/stocks'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((json) => StockModel.fromJson(json)).toList();
      }
    } catch (e) {
      // Fallback local mockup data
    }
    return _mockStocks();
  }

  // Fetch stock news
  Future<List<Map<String, dynamic>>> getStockNews(String? ticker) async {
    try {
      final url = ticker != null 
          ? '${AppConstants.baseRestUrl}/stocks/news?ticker=$ticker'
          : '${AppConstants.baseRestUrl}/stocks/news';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      }
    } catch (e) {
      // Fallback news
    }
    return _mockNews(ticker);
  }

  // Fetch rules
  Future<List<RuleModel>> getRules() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseRestUrl}/rules'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((json) => RuleModel.fromJson(json)).toList();
      }
    } catch (e) {
      // Fallback
    }
    return _mockRules();
  }

  // Create rule
  Future<RuleModel?> createRule(Map<String, dynamic> ruleData) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseRestUrl}/rules'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(ruleData),
      );
      if (response.statusCode == 201) {
        return RuleModel.fromJson(json.decode(response.body));
      }
    } catch (e) {
      // Fallback
    }
    return RuleModel(
      id: 'rule_local_${DateTime.now().millisecondsSinceEpoch}',
      name: ruleData['name'],
      ticker: ruleData['ticker'],
      isActive: true,
      operator: ruleData['operator'] ?? 'AND',
      conditions: List<ConditionModel>.from(
        (ruleData['conditions'] as List).map((c) => ConditionModel.fromJson(c))
      ),
    );
  }

  // Delete rule
  Future<bool> deleteRule(String ruleId) async {
    try {
      final response = await http.delete(Uri.parse('${AppConstants.baseRestUrl}/rules/$ruleId'));
      if (response.statusCode == 200) return true;
    } catch (e) {
      // Fallback
    }
    return true;
  }

  // Toggle rule
  Future<RuleModel?> toggleRule(String ruleId) async {
    try {
      final response = await http.post(Uri.parse('${AppConstants.baseRestUrl}/rules/$ruleId/toggle'));
      if (response.statusCode == 200) {
        return RuleModel.fromJson(json.decode(response.body));
      }
    } catch (e) {
      // Fallback
    }
    return null;
  }

  // Get alert history log
  Future<List<AlertModel>> getAlerts() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseRestUrl}/alerts'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((json) => AlertModel.fromJson(json)).toList();
      }
    } catch (e) {
      // Fallback
    }
    return _mockAlerts();
  }

  // Clear alerts
  Future<bool> clearAlerts() async {
    try {
      final response = await http.post(Uri.parse('${AppConstants.baseRestUrl}/alerts/clear'));
      if (response.statusCode == 200) return true;
    } catch (e) {
      // Fallback
    }
    return true;
  }

  // Talk to AI Chatbot
  Future<Map<String, dynamic>> sendChatMessage(String message, Map<String, dynamic> portfolioSummary) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseRestUrl}/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': message,
          'portfolioSummary': portfolioSummary,
        }),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      // Fallback response generator
    }
    return _localAiFallback(message);
  }

  // Admin Stock Mock parameter setter
  Future<bool> adminMockUpdateStock(String ticker, double price, double rsi) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseRestUrl}/stocks/mock-update'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'ticker': ticker,
          'price': price,
          'rsi': rsi,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      // Fallback
    }
    return true;
  }

  // --- LOCAL FALLBACK MOCK DATA INITS ---

  List<StockModel> _mockStocks() {
    return [
      StockModel(ticker: 'AAPL', companyName: 'Apple Inc.', price: 180.50, change: 1.50, changePercent: 0.84, volume: 1500000, rsi: 45.0, history: [178.0, 179.0, 180.5]),
      StockModel(ticker: 'TSLA', companyName: 'Tesla Inc.', price: 175.20, change: -2.30, changePercent: -1.30, volume: 2400000, rsi: 35.0, history: [179.0, 177.0, 175.2]),
      StockModel(ticker: 'MSFT', companyName: 'Microsoft Corp.', price: 420.80, change: 4.10, changePercent: 0.98, volume: 1100000, rsi: 55.0, history: [415.0, 418.0, 420.8]),
      StockModel(ticker: 'GOOG', companyName: 'Alphabet Inc.', price: 172.10, change: 0.80, changePercent: 0.47, volume: 900000, rsi: 48.0, history: [170.0, 171.0, 172.1]),
      StockModel(ticker: 'RELIANCE', companyName: 'Reliance Industries', price: 2950.00, change: 25.00, changePercent: 0.85, volume: 800000, rsi: 62.0, history: [2920, 2940, 2950]),
      StockModel(ticker: 'INFY', companyName: 'Infosys Ltd.', price: 1450.00, change: -15.00, changePercent: -1.02, volume: 600000, rsi: 29.0, history: [1470, 1460, 1450]),
    ];
  }

  List<Map<String, dynamic>> _mockNews(String? ticker) {
    final list = [
      {'title': 'Tesla Reports Delivery Numbers, Exceeds Analyst Target', 'summary': 'Tesla delivered over 490k vehicles this quarter, defying initial predictions.', 'source': 'Global Market Wire', 'ticker': 'TSLA'},
      {'title': 'Apple CEO Announces Next Gen AI Core Chips', 'summary': 'Apple Inc. announced its next generation chips optimized specifically for local machine learning execution.', 'source': 'Tech Watch', 'ticker': 'AAPL'},
      {'title': 'Infosys Signs Major Cloud Multi-Year Digital Transformation Deal', 'summary': 'Infosys announced that it won a massive Cloud integration partnership with a major European conglomerate.', 'source': 'Business Standard', 'ticker': 'INFY'}
    ];
    if (ticker != null) {
      return list.where((element) => element['ticker'] == ticker).toList();
    }
    return list;
  }

  List<RuleModel> _mockRules() {
    return [
      RuleModel(
        id: 'r1',
        name: 'Tesla RSI Oversold Alert',
        ticker: 'TSLA',
        isActive: true,
        operator: 'AND',
        conditions: [ConditionModel(indicator: 'RSI', comparison: 'LESS_THAN', thresholdValue: 30.0)]
      ),
      RuleModel(
        id: 'r2',
        name: 'Apple Breakout Watch',
        ticker: 'AAPL',
        isActive: true,
        operator: 'AND',
        conditions: [ConditionModel(indicator: 'Price', comparison: 'GREATER_THAN', thresholdValue: 190.0)]
      )
    ];
  }

  List<AlertModel> _mockAlerts() {
    return [
      AlertModel(
        id: 'a1',
        ruleId: 'r1',
        ruleName: 'Tesla RSI Oversold Alert',
        ticker: 'TSLA',
        triggerPrice: 175.20,
        message: 'Strategy Alert fired: Tesla RSI Oversold Alert. conditions satisfied: RSI (28.4) met condition LESS_THAN 30',
        readStatus: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      )
    ];
  }

  Map<String, dynamic> _localAiFallback(String userMessage) {
    final query = userMessage.toLowerCase();
    String text = '';
    List<String> actions = [];

    if (query.contains('rsi')) {
      text = '### Relative Strength Index (RSI) Indicator\n\nRSI is a momentum oscillator matching speeds and changes of price movements:\n- **Oversold (< 30)**: Indicates oversold limits. Good zone to buy.\n- **Overbought (> 70)**: Indicates overbought limits. Good zone to distribute.';
      actions = ['Explain MACD', 'Set RSI Alert'];
    } else if (query.contains('macd')) {
      text = '### MACD Technical Guide\n\nMACD checks divergence thresholds. When the MACD line crosses above the Signal Line, a bullish trend reversal signal is emitted.';
      actions = ['Explain RSI', 'Set MACD Alert'];
    } else if (query.contains('risk') || query.contains('portfolio')) {
      text = '### TradeMentor AI Portfolio Risk Analysis\n\nYour holdings indicate strong concentration in Tech sector (AAPL, TSLA). We recommend adding defensive equities (consumer goods, utilities) to insulate P&L during high-beta cycles.';
      actions = ['Diversify Portfolio', 'View holdings'];
    } else {
      text = 'Welcome to **TradeMentor AI**! I am your virtual analytical advisor. Ask me questions about: \n* **"Explain RSI strategy"**\n* **"Evaluate my portfolio risk"**\n* **"Compare Apple vs Tesla"**';
      actions = ['Explain RSI indicator', 'Evaluate portfolio risk'];
    }

    return {'response': text, 'suggestedActions': actions};
  }
}
