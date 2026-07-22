import 'package:flutter_test/flutter_test.dart';
import 'package:tradementor/src/models/stock_model.dart';

void main() {
  group('StockModel Json Deserialization Tests', () {
    test('fromJson parses price, change, changePercent, volume, rsi, and history correctly', () {
      final json = {
        'ticker': 'AAPL',
        'companyName': 'Apple Inc.',
        'price': 180.50,
        'change': 1.50,
        'changePercent': 0.84,
        'volume': 1500000,
        'rsi': 45.0,
        'history': [178.0, 179.0, 180.5]
      };

      final stock = StockModel.fromJson(json);

      expect(stock.ticker, 'AAPL');
      expect(stock.companyName, 'Apple Inc.');
      expect(stock.price, 180.50);
      expect(stock.change, 1.50);
      expect(stock.changePercent, 0.84);
      expect(stock.volume, 1500000);
      expect(stock.rsi, 45.0);
      expect(stock.history, [178.0, 179.0, 180.5]);
    });

    test('fromJson handles nulls and uses default fallback values', () {
      final json = {
        'ticker': 'TSLA',
        'companyName': 'Tesla Inc.',
      };

      final stock = StockModel.fromJson(json);

      expect(stock.ticker, 'TSLA');
      expect(stock.companyName, 'Tesla Inc.');
      expect(stock.price, 0.0);
      expect(stock.change, 0.0);
      expect(stock.changePercent, 0.0);
      expect(stock.volume, 0);
      expect(stock.rsi, 50.0);
      expect(stock.history, isEmpty);
    });
  });

  group('RuleModel and ConditionModel Deserialization Tests', () {
    test('fromJson parses RuleModel and nested ConditionModel correctly', () {
      final json = {
        'id': 'rule_1',
        'name': 'Tesla RSI Oversold Alert',
        'ticker': 'TSLA',
        'isActive': true,
        'operator': 'AND',
        'conditions': [
          {
            'indicator': 'RSI',
            'comparison': 'LESS_THAN',
            'thresholdValue': 30.0
          }
        ]
      };

      final rule = RuleModel.fromJson(json);

      expect(rule.id, 'rule_1');
      expect(rule.name, 'Tesla RSI Oversold Alert');
      expect(rule.ticker, 'TSLA');
      expect(rule.isActive, true);
      expect(rule.operator, 'AND');
      expect(rule.conditions.length, 1);
      expect(rule.conditions[0].indicator, 'RSI');
      expect(rule.conditions[0].comparison, 'LESS_THAN');
      expect(rule.conditions[0].thresholdValue, 30.0);
    });
  });
}
