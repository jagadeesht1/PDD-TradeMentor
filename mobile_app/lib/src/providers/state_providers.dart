import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/stock_model.dart';
import '../services/api_service.dart';
import '../core/constants/app_constants.dart';

// 1. Theme state notifier
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark);

  void toggleTheme() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

// 2. Authentication provider
class AuthState {
  final bool isAuthenticated;
  final String? email;
  final String? name;
  final String riskTolerance;
  final String subscriptionLevel;

  AuthState({
    required this.isAuthenticated,
    this.email,
    this.name,
    this.riskTolerance = 'Moderate',
    this.subscriptionLevel = 'Free',
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? email,
    String? name,
    String? riskTolerance,
    String? subscriptionLevel,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      email: email ?? this.email,
      name: name ?? this.name,
      riskTolerance: riskTolerance ?? this.riskTolerance,
      subscriptionLevel: subscriptionLevel ?? this.subscriptionLevel,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(isAuthenticated: false));

  void login(String email, String password) {
    state = AuthState(
      isAuthenticated: true,
      email: email,
      name: email.split('@').first.toUpperCase(),
      riskTolerance: 'Moderate',
      subscriptionLevel: 'Free',
    );
  }

  void setupProfile(String name, String risk, String sub) {
    state = state.copyWith(
      name: name,
      riskTolerance: risk,
      subscriptionLevel: sub,
    );
  }

  void logout() {
    state = AuthState(isAuthenticated: false);
  }
}

// 3. Stocks data stream provider (via WebSocket + HTTP updates)
final stocksListProvider = StateNotifierProvider<StocksNotifier, AsyncValue<List<StockModel>>>((ref) {
  final notifier = StocksNotifier(ref);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

class StocksNotifier extends StateNotifier<AsyncValue<List<StockModel>>> {
  final Ref _ref;
  WebSocketChannel? _channel;
  bool _isDisposed = false;

  StocksNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadStocks();
  }

  Future<void> loadStocks() async {
    try {
      final stocks = await ApiService.instance.getStocks();
      if (!_isDisposed) {
        state = AsyncValue.data(stocks);
        _connectWebSocket(stocks);
      }
    } catch (e, stack) {
      if (!_isDisposed) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  void _connectWebSocket(List<StockModel> initialStocks) {
    if (_isDisposed) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(AppConstants.baseWsUrl));
      
      final tickers = initialStocks.map((s) => s.ticker).toList();
      _channel!.sink.add(json.encode({
        'action': 'subscribe',
        'tickers': tickers,
      }));

      _channel!.stream.listen((message) {
        if (_isDisposed) return;
        try {
          final data = json.decode(message);
          if (data['type'] == 'tick') {
            final updatedStock = StockModel.fromJson(data);
            _updateStockPrice(updatedStock);
          } else if (data['type'] == 'alert') {
            final newAlert = AlertModel.fromJson(data);
            _ref.read(alertsLogProvider.notifier).addAlert(newAlert);
          }
        } catch (e) {
          // ignore parsing error
        }
      }, onError: (err) {
        _reconnect(initialStocks);
      }, onDone: () {
        _reconnect(initialStocks);
      });
    } catch (e) {
      _reconnect(initialStocks);
    }
  }

  void _reconnect(List<StockModel> initialStocks) {
    if (_isDisposed) return;
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isDisposed) {
        _connectWebSocket(initialStocks);
      }
    });
  }

  void _updateStockPrice(StockModel updatedStock) {
    state.whenData((stocks) {
      final index = stocks.indexWhere((s) => s.ticker == updatedStock.ticker);
      final updatedList = List<StockModel>.from(stocks);
      if (index != -1) {
        updatedList[index] = updatedStock;
      } else {
        updatedList.add(updatedStock);
      }
      state = AsyncValue.data(updatedList);
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _channel?.sink.close();
    super.dispose();
  }
}

// 4. Watchlist provider
final watchlistProvider = StateNotifierProvider<WatchlistNotifier, List<String>>((ref) {
  return WatchlistNotifier();
});

class WatchlistNotifier extends StateNotifier<List<String>> {
  WatchlistNotifier() : super(['AAPL', 'TSLA', 'MSFT']);

  void addTicker(String ticker) {
    if (!state.contains(ticker.toUpperCase())) {
      state = [...state, ticker.toUpperCase()];
    }
  }

  void removeTicker(String ticker) {
    state = state.where((t) => t != ticker.toUpperCase()).toList();
  }
}

// 5. Portfolio holdings provider
class Holding {
  final String id;
  final String ticker;
  final String name;
  final double sharesCount;
  final double averageBuyPrice;
  final double currentPrice;

  Holding({
    required this.id,
    required this.ticker,
    required this.name,
    required this.sharesCount,
    required this.averageBuyPrice,
    required this.currentPrice,
  });

  double get investedAmount => sharesCount * averageBuyPrice;
  double get currentAmount => sharesCount * currentPrice;
  double get profitOrLoss => currentAmount - investedAmount;
  double get profitOrLossPercent => investedAmount == 0 ? 0.0 : (profitOrLoss / investedAmount) * 100;

  Holding copyWith({double? currentPrice}) {
    return Holding(
      id: id,
      ticker: ticker,
      name: name,
      sharesCount: sharesCount,
      averageBuyPrice: averageBuyPrice,
      currentPrice: currentPrice ?? this.currentPrice,
    );
  }
}

final portfolioProvider = StateNotifierProvider<PortfolioNotifier, List<Holding>>((ref) {
  final notifier = PortfolioNotifier();
  
  ref.listen<AsyncValue<List<StockModel>>>(stocksListProvider, (previous, next) {
    next.whenData((stocks) {
      notifier.updatePrices(stocks);
    });
  });

  return notifier;
});

class PortfolioNotifier extends StateNotifier<List<Holding>> {
  PortfolioNotifier()
      : super([
          Holding(id: 'h1', ticker: 'AAPL', name: 'Apple Inc.', sharesCount: 10, averageBuyPrice: 175.0, currentPrice: 180.50),
          Holding(id: 'h2', ticker: 'TSLA', name: 'Tesla Inc.', sharesCount: 5, averageBuyPrice: 180.0, currentPrice: 175.20),
          Holding(id: 'h3', ticker: 'MSFT', name: 'Microsoft Corp.', sharesCount: 3, averageBuyPrice: 410.0, currentPrice: 420.80),
        ]);

  void buyStock(String ticker, String name, double shares, double price) {
    final existingIndex = state.indexWhere((h) => h.ticker == ticker.toUpperCase());
    if (existingIndex != -1) {
      final existing = state[existingIndex];
      final totalShares = existing.sharesCount + shares;
      final avgPrice = ((existing.sharesCount * existing.averageBuyPrice) + (shares * price)) / totalShares;
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            Holding(
              id: existing.id,
              ticker: ticker,
              name: name,
              sharesCount: totalShares,
              averageBuyPrice: avgPrice,
              currentPrice: price,
            )
          else
            state[i]
      ];
    } else {
      state = [
        ...state,
        Holding(
          id: 'h_${DateTime.now().millisecondsSinceEpoch}',
          ticker: ticker.toUpperCase(),
          name: name,
          sharesCount: shares,
          averageBuyPrice: price,
          currentPrice: price,
        )
      ];
    }
  }

  void sellStock(String ticker, double shares) {
    final existingIndex = state.indexWhere((h) => h.ticker == ticker.toUpperCase());
    if (existingIndex != -1) {
      final existing = state[existingIndex];
      if (existing.sharesCount <= shares) {
        state = state.where((h) => h.ticker != ticker.toUpperCase()).toList();
      } else {
        state = [
          for (int i = 0; i < state.length; i++)
            if (i == existingIndex)
              Holding(
                id: existing.id,
                ticker: existing.ticker,
                name: existing.name,
                sharesCount: existing.sharesCount - shares,
                averageBuyPrice: existing.averageBuyPrice,
                currentPrice: existing.currentPrice,
              )
            else
              state[i]
        ];
      }
    }
  }

  void updatePrices(List<StockModel> stocks) {
    state = state.map((holding) {
      final match = stocks.firstWhere(
        (s) => s.ticker == holding.ticker,
        orElse: () => StockModel(ticker: holding.ticker, companyName: holding.name, price: holding.currentPrice, change: 0, changePercent: 0, volume: 0, rsi: 50, history: []),
      );
      return holding.copyWith(currentPrice: match.price);
    }).toList();
  }
}

// 6. Strategy alert rules provider
final rulesListProvider = StateNotifierProvider<RulesNotifier, List<RuleModel>>((ref) {
  return RulesNotifier();
});

class RulesNotifier extends StateNotifier<List<RuleModel>> {
  RulesNotifier() : super([]) {
    loadRules();
  }

  Future<void> loadRules() async {
    final list = await ApiService.instance.getRules();
    state = list;
  }

  Future<void> addNewRule(String name, String ticker, List<ConditionModel> conditions, String op) async {
    final payload = {
      'name': name,
      'ticker': ticker.toUpperCase(),
      'operator': op,
      'conditions': conditions.map((c) => c.toJson()).toList(),
    };
    final created = await ApiService.instance.createRule(payload);
    if (created != null) {
      state = [...state, created];
    }
  }

  Future<void> removeRule(String ruleId) async {
    final success = await ApiService.instance.deleteRule(ruleId);
    if (success) {
      state = state.where((r) => r.id != ruleId).toList();
    }
  }

  Future<void> toggleRule(String ruleId) async {
    final toggled = await ApiService.instance.toggleRule(ruleId);
    if (toggled != null) {
      state = state.map((r) => r.id == ruleId ? toggled : r).toList();
    } else {
      // Local toggle
      state = state.map((r) {
        if (r.id == ruleId) {
          return RuleModel(id: r.id, name: r.name, ticker: r.ticker, isActive: !r.isActive, operator: r.operator, conditions: r.conditions);
        }
        return r;
      }).toList();
    }
  }
}

// 7. Alert history alerts log provider
final alertsLogProvider = StateNotifierProvider<AlertsNotifier, List<AlertModel>>((ref) {
  return AlertsNotifier();
});

class AlertsNotifier extends StateNotifier<List<AlertModel>> {
  AlertsNotifier() : super([]) {
    refreshAlerts();
  }

  Future<void> refreshAlerts() async {
    final list = await ApiService.instance.getAlerts();
    state = list;
  }

  void addAlert(AlertModel alert) {
    if (!state.any((a) => a.id == alert.id)) {
      state = [alert, ...state];
    }
  }

  Future<void> clearAll() async {
    await ApiService.instance.clearAlerts();
    state = [];
  }
}

// 8. Chatbot messages history provider
final chatHistoryProvider = StateNotifierProvider<ChatHistoryNotifier, List<ChatMessageModel>>((ref) {
  return ChatHistoryNotifier();
});

class ChatHistoryNotifier extends StateNotifier<List<ChatMessageModel>> {
  ChatHistoryNotifier()
      : super([
          ChatMessageModel(
            id: 'c1',
            sender: 'ai',
            content: 'Hello! I am **TradeMentor AI**, your virtual technical analyst and trading coach. Ask me questions like:\n* *"Explain RSI strategy"* \n* *"How is my portfolio risk profile?"*\n* *"Compare AAPL vs TSLA"*',
            timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          )
        ]);

  Future<void> sendMessage(String text, HoldingSummary summary) async {
    final userMsg = ChatMessageModel(
      id: 'msg_u_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      content: text,
      timestamp: DateTime.now(),
    );
    state = [...state, userMsg];

    final responseMap = await ApiService.instance.sendChatMessage(
      text,
      {'totalInvested': summary.totalInvested, 'holdingsCount': summary.holdingsCount},
    );

    final aiMsg = ChatMessageModel(
      id: 'msg_a_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'ai',
      content: responseMap['response'] ?? 'Sorry, the server was offline and I failed to analyze the market.',
      timestamp: DateTime.now(),
    );
    state = [...state, aiMsg];
  }
}

class HoldingSummary {
  final double totalInvested;
  final int holdingsCount;
  HoldingSummary({required this.totalInvested, required this.holdingsCount});
}
