// Data Models representing stocks, alert rules, triggered alarms, and chatbot messages.

class StockModel {
  final String ticker;
  final String companyName;
  final double price;
  final double change;
  final double changePercent;
  final int volume;
  final double rsi;
  final List<double> history;

  StockModel({
    required this.ticker,
    required this.companyName,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.volume,
    required this.rsi,
    required this.history,
  });

  factory StockModel.fromJson(Map<String, dynamic> json) {
    return StockModel(
      ticker: json['ticker'] ?? '',
      companyName: json['companyName'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      change: (json['change'] ?? 0.0).toDouble(),
      changePercent: (json['changePercent'] ?? 0.0).toDouble(),
      volume: json['volume'] ?? 0,
      rsi: (json['rsi'] ?? 50.0).toDouble(),
      history: List<double>.from((json['history'] ?? []).map((x) => x.toDouble())),
    );
  }
}

class RuleModel {
  final String id;
  final String name;
  final String ticker;
  final bool isActive;
  final String operator;
  final List<ConditionModel> conditions;

  RuleModel({
    required this.id,
    required this.name,
    required this.ticker,
    required this.isActive,
    required this.operator,
    required this.conditions,
  });

  factory RuleModel.fromJson(Map<String, dynamic> json) {
    return RuleModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      ticker: json['ticker'] ?? '',
      isActive: json['isActive'] ?? true,
      operator: json['operator'] ?? 'AND',
      conditions: List<ConditionModel>.from(
        (json['conditions'] ?? []).map((x) => ConditionModel.fromJson(x))
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ticker': ticker,
    'isActive': isActive,
    'operator': operator,
    'conditions': conditions.map((x) => x.toJson()).toList(),
  };
}

class ConditionModel {
  final String indicator;
  final String comparison;
  final double thresholdValue;

  ConditionModel({
    required this.indicator,
    required this.comparison,
    required this.thresholdValue,
  });

  factory ConditionModel.fromJson(Map<String, dynamic> json) {
    return ConditionModel(
      indicator: json['indicator'] ?? 'Price',
      comparison: json['comparison'] ?? 'LESS_THAN',
      thresholdValue: (json['thresholdValue'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'indicator': indicator,
    'comparison': comparison,
    'thresholdValue': thresholdValue,
  };
}

class AlertModel {
  final String id;
  final String ruleId;
  final String ruleName;
  final String ticker;
  final double triggerPrice;
  final String message;
  final bool readStatus;
  final String createdAt;

  AlertModel({
    required this.id,
    required this.ruleId,
    required this.ruleName,
    required this.ticker,
    required this.triggerPrice,
    required this.message,
    required this.readStatus,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? '',
      ruleId: json['ruleId'] ?? '',
      ruleName: json['ruleName'] ?? '',
      ticker: json['ticker'] ?? '',
      triggerPrice: (json['triggerPrice'] ?? 0.0).toDouble(),
      message: json['message'] ?? '',
      readStatus: json['readStatus'] ?? false,
      createdAt: json['createdAt'] ?? '',
    );
  }
}

class ChatMessageModel {
  final String id;
  final String sender;
  final String content;
  final DateTime timestamp;

  ChatMessageModel({
    required this.id,
    required this.sender,
    required this.content,
    required this.timestamp,
  });
}
