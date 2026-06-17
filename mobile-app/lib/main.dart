import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'onboarding_screens.dart';
import 'market_screens.dart';
import 'stock_details_screen.dart';
import 'portfolio_screens.dart';
import 'alerts_screens.dart';
import 'ai_mentor_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => MarketProvider(),
      child: const TradeMentorApp(),
    ),
  );
}

// Global Custom Colors matching Groww/Zerodha dark themes
class AppColors {
  static const Color background = Color(0xFF0B121E);
  static const Color surface = Color(0xFF141F32);
  static const Color gainGreen = Color(0xFF00D09C);
  static const Color lossRed = Color(0xFFFF5353);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white60;
  static const Color textMuted = Colors.white30;
}

class TradeMentorApp extends StatelessWidget {
  const TradeMentorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TradeMentor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.surface,
          primary: AppColors.gainGreen,
          error: AppColors.lossRed,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      home: const RootAppNavigator(),
    );
  }
}

class RootAppNavigator extends StatelessWidget {
  const RootAppNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarketProvider>(context);
    switch (provider.currentScreen) {
      case 'SPLASH':
        return const SplashOnboardingScreen();
      case 'LOGIN':
        return const LoginScreen();
      case 'REGISTER':
        return const RegisterScreen();
      case 'FORGOT':
        return const ForgotPasswordScreen();
      case 'RESET':
        return const ResetPasswordScreen();
      case 'RISK_QUIZ':
        return const RiskQuizScreen();
      case 'DASHBOARD':
      default:
        return const MainLayoutScreen();
    }
  }
}

// Market state provider managing navigation, http requests, polling, sparkline logs and offline fallbacks
class MarketProvider with ChangeNotifier {
  String _baseUrl = kIsWeb
      ? 'http://localhost:5000'
      : (defaultTargetPlatform == TargetPlatform.android ? 'http://10.0.2.2:5000' : 'http://localhost:5000');
  String get baseUrl => _baseUrl;

  void updateBaseUrl(String newUrl) {
    _baseUrl = newUrl;
    notifyListeners();
    fetchMarketData();
  }

  // Navigation states
  String _currentScreen = 'SPLASH';
  String get currentScreen => _currentScreen;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  void setScreen(String screen) {
    _currentScreen = screen;
    notifyListeners();
  }

  void setLoggedIn(bool val) {
    _isLoggedIn = val;
    if (val && _userId == null) {
      // Offline fallback seeding
      _userId = 'mock_offline_user_id';
      _walletBalance = 100000.0;
      _portfolio = {
        'holdings': [],
        'totalInvested': 0.0,
        'totalCurrentValue': 0.0,
        'totalUnrealized': 0.0,
        'totalRealizedPnL': 0.0,
      };
      // Mock fallback stocks
      _stocks = [
        { 'symbol': 'RELIANCE', 'name': 'Reliance Industries Ltd.', 'exchange': 'NSE', 'currentPrice': 2450.00, 'openPrice': 2450.00, 'sector': 'Energy', 'pChange': 0.0 },
        { 'symbol': 'TCS', 'name': 'Tata Consultancy Services Ltd.', 'exchange': 'NSE', 'currentPrice': 3480.00, 'openPrice': 3480.00, 'sector': 'IT', 'pChange': 0.0 },
        { 'symbol': 'HDFCBANK', 'name': 'HDFC Bank Ltd.', 'exchange': 'NSE', 'currentPrice': 1620.00, 'openPrice': 1620.00, 'sector': 'Financial Services', 'pChange': 0.0 },
        { 'symbol': 'INFY', 'name': 'Infosys Ltd.', 'exchange': 'NSE', 'currentPrice': 1475.00, 'openPrice': 1475.00, 'sector': 'IT', 'pChange': 0.0 },
      ];
      _indices = [
        { 'symbol': 'NIFTY 50', 'name': 'Nifty 50 Index', 'exchange': 'NSE', 'currentPrice': 22400.00, 'openPrice': 22400.00, 'sector': 'Index', 'pChange': 0.0 },
      ];
    }
    notifyListeners();
  }

  String? _userId;
  String? get userId => _userId;

  String? _token;
  String? get token => _token;

  String _userName = 'Demo Investor';
  String get userName => _userName;

  String _userEmail = '';
  String get userEmail => _userEmail;

  double _walletBalance = 100000.00;
  double get walletBalance => _walletBalance;

  List<dynamic> _stocks = [];
  List<dynamic> get stocks => _stocks;

  List<dynamic> _indices = [];
  List<dynamic> get indices => _indices;

  List<dynamic> _alerts = [];
  List<dynamic> get alerts => _alerts;

  Map<String, dynamic>? _portfolio;
  Map<String, dynamic>? get portfolio => _portfolio;

  List<dynamic> _trades = [];
  List<dynamic> get trades => _trades;

  final Map<String, List<double>> _priceHistory = {};
  Map<String, List<double>> get priceHistory => _priceHistory;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  Timer? _pollingTimer;

  // Wallet margin history credits/debits
  final List<Map<String, dynamic>> _walletLogs = [
    {
      'id': 1,
      'type': 'CREDIT',
      'description': 'Simulated Initial Seed Allocation',
      'amount': 100000.00,
      'date': DateTime.now().toIso8601String()
    }
  ];
  List<Map<String, dynamic>> get walletLogs => _walletLogs;

  void depositCash(double amount, String desc) {
    _walletBalance += amount;
    _walletLogs.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch,
      'type': 'CREDIT',
      'description': desc,
      'amount': amount,
      'date': DateTime.now().toIso8601String()
    });
    notifyListeners();
  }

  void withdrawCash(double amount, String desc) {
    _walletBalance -= amount;
    _walletLogs.insert(0, {
      'id': DateTime.now().millisecondsSinceEpoch,
      'type': 'DEBIT',
      'description': desc,
      'amount': amount,
      'date': DateTime.now().toIso8601String()
    });
    notifyListeners();
  }

  // AI Chat variables
  final List<Map<String, String>> _aiChatHistory = [
    {
      'sender': 'ai',
      'text': 'Welcome to TradeMentor AI Assistant! 🤖\n\nI can analyze Indian equities, run technical scanners, suggest asset allocations, or explain glossary concepts. What are you looking to scan today?'
    }
  ];
  List<Map<String, String>> get aiChatHistory => _aiChatHistory;

  bool _aiLoading = false;
  bool get aiLoading => _aiLoading;

  String _riskProfile = 'moderate';
  String get riskProfile => _riskProfile;

  void setRiskProfile(String profile) {
    _riskProfile = profile;
    notifyListeners();
  }

  void clearChat() {
    _aiChatHistory.clear();
    _aiChatHistory.add({
      'sender': 'ai',
      'text': 'Welcome to TradeMentor AI Assistant! 🤖\n\nI can analyze Indian equities, run technical scanners, suggest asset allocations, or explain glossary concepts. What are you looking to scan today?'
    });
    notifyListeners();
  }

  Future<void> sendAiMessage(String msg) async {
    if (msg.trim().isEmpty) return;
    _aiChatHistory.add({'sender': 'user', 'text': msg});
    _aiLoading = true;
    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/ai/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': msg,
          'riskProfile': _riskProfile,
        }),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _aiChatHistory.add({'sender': 'ai', 'text': data['reply'] ?? 'No response'});
      } else {
        _aiChatHistory.add({'sender': 'ai', 'text': 'Sorry, my technical analysis processors are temporarily offline. Verify your server connection.'});
      }
    } catch (e) {
      _aiChatHistory.add({'sender': 'ai', 'text': 'Network failure. Ensure your Express Docker container is online.'});
    } finally {
      _aiLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchSentiment(String symbol) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/ai/sentiment/$symbol')).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return json.decode(res.body);
      }
    } catch (e) {
      debugPrint("Error fetching sentiment: $e");
    }
    return null;
  }

  MarketProvider() {
    _init();
  }

  Future<void> _init() async {
    _currentScreen = 'SPLASH';
    _isLoggedIn = false;
    notifyListeners();
    
    // Attempt Auto-Discovery of backend on local network before polling
    if (!kIsWeb) {
      await _discoverBackend();
    }
    
    startPolling();
  }

  Future<void> _discoverBackend() async {
    try {
      final info = NetworkInfo();
      String? wifiIP = await info.getWifiIP();
      
      List<String> prefixesToScan = [];
      
      if (wifiIP != null && wifiIP.contains('.')) {
        prefixesToScan.add(wifiIP.substring(0, wifiIP.lastIndexOf('.')));
      } else {
        // Fallback: If permissions blocked Wifi IP, scan common subnets
        debugPrint('Wi-Fi IP unavailable (likely permission). Falling back to common subnets...');
        prefixesToScan.addAll(['172.23.51', '192.168.1', '192.168.0', '10.0.2', '10.0.0']);
      }

      for (String prefix in prefixesToScan) {
        debugPrint('Scanning subnet $prefix.* for TradeMentor backend...');
        
        // Scan common IPs first for speed
        final commonSuffixes = ['1', '100', '101', '146', '12', '14', '15'];
        if (wifiIP != null && wifiIP.contains('.')) commonSuffixes.add(wifiIP.split('.').last);
        
        for (var suffix in commonSuffixes) {
          final testUrl = 'http://$prefix.$suffix:5000';
          try {
            final res = await http.get(Uri.parse('$testUrl/api/stocks')).timeout(const Duration(milliseconds: 300));
            if (res.statusCode == 200) {
              _baseUrl = testUrl;
              debugPrint('✅ Auto-discovered backend at: $_baseUrl');
              return;
            }
          } catch (_) {}
        }
        
        // Parallel scan all 255 for this prefix
        final futures = <Future<String?>>[];
        for (int i = 1; i <= 255; i++) {
          futures.add(() async {
            final testUrl = 'http://$prefix.$i:5000';
            try {
              final res = await http.get(Uri.parse('$testUrl/api/stocks')).timeout(const Duration(milliseconds: 400));
              if (res.statusCode == 200) return testUrl;
            } catch (_) {}
            return null;
          }());
        }
        
        final results = await Future.wait(futures);
        final found = results.firstWhere((url) => url != null, orElse: () => null);
        if (found != null) {
          _baseUrl = found;
          debugPrint('✅ Auto-discovered backend at: $_baseUrl');
          return;
        }
      }
    } catch (e) {
      debugPrint('Auto-discovery failed: $e');
    }
  }

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => fetchMarketData());
    fetchMarketData();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// Real login via POST /api/auth/login — returns null on success, error string on failure
  Future<String?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 8));
      final data = json.decode(res.body);
      if (res.statusCode == 200) {
        _token = data['token'];
        _userId = data['userId'].toString();
        _userName = data['name'] ?? 'Investor';
        _userEmail = data['email'] ?? email;
        _walletBalance = (data['walletBalance'] as num).toDouble();
        _isLoggedIn = true;
        _errorMessage = '';
        fetchPortfolio();
        fetchTradeHistory();
        fetchUserAlerts();
        notifyListeners();
        return null; // success
      } else {
        return data['error'] ?? 'Login failed';
      }
    } catch (e) {
      return 'Cannot reach server. Check your backend URL in Settings.';
    }
  }

  /// Real register via POST /api/auth/register — returns null on success, error string on failure
  Future<String?> register(String name, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 8));
      final data = json.decode(res.body);
      if (res.statusCode == 201) {
        _token = data['token'];
        _userId = data['userId'].toString();
        _userName = data['name'] ?? name;
        _userEmail = data['email'] ?? email;
        _walletBalance = (data['walletBalance'] as num).toDouble();
        _isLoggedIn = true;
        _errorMessage = '';
        notifyListeners();
        return null; // success
      } else {
        return data['error'] ?? 'Registration failed';
      }
    } catch (e) {
      return 'Cannot reach server. Check your backend URL in Settings.';
    }
  }

  /// Native Google Auth via google_sign_in package
  Future<String?> googleLogin() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(clientId: '665504381175-l1h8mpm1lm88823b3su2690qfh4mjh39.apps.googleusercontent.com');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        return 'Google Sign-In aborted.'; // User canceled
      }

      final res = await http.post(
        Uri.parse('$_baseUrl/api/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': googleUser.displayName ?? 'Google User', 'email': googleUser.email}),
      ).timeout(const Duration(seconds: 8));
      
      final data = json.decode(res.body);
      if (res.statusCode == 200) {
        _token = data['token'];
        _userId = data['userId'].toString();
        _userName = data['name'] ?? googleUser.displayName ?? 'Google User';
        _userEmail = data['email'] ?? googleUser.email;
        _walletBalance = (data['walletBalance'] as num).toDouble();
        _isLoggedIn = true;
        _errorMessage = '';
        fetchPortfolio();
        fetchTradeHistory();
        fetchUserAlerts();
        notifyListeners();
        return null; // success
      } else {
        await googleSignIn.signOut();
        return data['error'] ?? 'Google Login failed';
      }
    } catch (e) {
      // NOTE: This will catch PlatformException if SHA-1 / Google Cloud is not configured.
      return 'Google Sign In Error. Ensure you have configured Google Cloud Console SHA-1 fingerprints for this app. Details: $e';
    }
  }

  Future<void> fetchMarketData() async {
    try {
      final stocksRes = await http.get(Uri.parse('$_baseUrl/api/stocks')).timeout(const Duration(seconds: 3));
      final indicesRes = await http.get(Uri.parse('$_baseUrl/api/indices')).timeout(const Duration(seconds: 3));

      if (stocksRes.statusCode == 200 && indicesRes.statusCode == 200) {
        _stocks = json.decode(stocksRes.body);
        _indices = json.decode(indicesRes.body);
        _errorMessage = '';

        for (var stock in _stocks) {
          _updateHistory(stock['symbol'], (stock['currentPrice'] as num).toDouble());
        }
        for (var idx in _indices) {
          _updateHistory(idx['symbol'], (idx['currentPrice'] as num).toDouble());
        }

        if (_userId != null && _userId != 'mock_offline_user_id') {
          fetchUserAlerts();
          fetchPortfolio();
          fetchTradeHistory();
        }
      } else {
        _errorMessage = 'Error loading endpoints from Express API';
      }
    } catch (e) {
      if (_userId == 'mock_offline_user_id') {
        // Fluctuating offline metrics for testing offline
        for (var s in _stocks) {
          final pctChange = (DateTime.now().second % 6) - 3.0;
          s['currentPrice'] = (s['currentPrice'] as num).toDouble() * (1.0 + (pctChange / 100.0));
          s['pChange'] = pctChange;
          _updateHistory(s['symbol'], s['currentPrice']);
        }
        _errorMessage = '';
      } else {
        _errorMessage = 'Cannot reach backend server. Verify address configuration.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateHistory(String symbol, double price) {
    if (!_priceHistory.containsKey(symbol)) {
      _priceHistory[symbol] = [];
    }
    _priceHistory[symbol]!.add(price);
    if (_priceHistory[symbol]!.length > 15) {
      _priceHistory[symbol]!.removeAt(0);
    }
  }

  Future<void> fetchUserAlerts() async {
    if (_userId == null || _userId == 'mock_offline_user_id') return;
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/alerts/$_userId'));
      if (res.statusCode == 200) {
        _alerts = json.decode(res.body);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading rules: $e");
    }
  }

  Future<void> fetchPortfolio() async {
    if (_userId == null || _userId == 'mock_offline_user_id') return;
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/portfolio/$_userId')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        _portfolio = json.decode(res.body);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading portfolio: $e");
    }
  }

  Future<void> fetchTradeHistory() async {
    if (_userId == null || _userId == 'mock_offline_user_id') return;
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/trades/$_userId?limit=50')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _trades = data['trades'] ?? [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading trade history: $e");
    }
  }

  Future<bool> createAlert(String symbol, double targetPrice, String criteria) async {
    if (_userId == null) return false;
    if (_userId == 'mock_offline_user_id') {
      _alerts.insert(0, {
        '_id': DateTime.now().millisecondsSinceEpoch.toString(),
        'userId': _userId,
        'symbol': symbol,
        'targetPrice': targetPrice,
        'criteria': criteria,
        'isTriggered': false,
        'createdAt': DateTime.now().toIso8601String()
      });
      notifyListeners();
      return true;
    }
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/alerts'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'symbol': symbol,
          'targetPrice': targetPrice,
          'criteria': criteria,
        }),
      );
      if (res.statusCode == 201) {
        fetchUserAlerts();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error making alert: $e");
      return false;
    }
  }

  Future<bool> deleteAlert(String alertId) async {
    if (_userId == 'mock_offline_user_id') {
      _alerts.removeWhere((a) => a['_id'] == alertId);
      notifyListeners();
      return true;
    }
    try {
      final res = await http.delete(Uri.parse('$_baseUrl/api/alerts/$alertId')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        fetchUserAlerts();
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting alert: $e");
    }
    return false;
  }

  Future<Map<String, dynamic>> executeTrade(String symbol, String type, int quantity) async {
    if (_userId == null) {
      return {'success': false, 'error': 'User not initialized'};
    }
    final price = _stocks.firstWhere((s) => s['symbol'] == symbol)['currentPrice'] as double;
    final totalValue = price * quantity;

    if (_userId == 'mock_offline_user_id') {
      if (type == 'BUY' && totalValue > _walletBalance) {
        return {'success': false, 'error': 'Insufficient balance'};
      }

      if (type == 'BUY') {
        _walletBalance -= totalValue;
        final list = _portfolio!['holdings'] as List;
        final idx = list.indexWhere((h) => h['symbol'] == symbol);
        if (idx >= 0) {
          final newQty = list[idx]['quantity'] + quantity;
          list[idx]['quantity'] = newQty;
          list[idx]['totalInvested'] += totalValue;
          list[idx]['averageBuyPrice'] = list[idx]['totalInvested'] / newQty;
        } else {
          list.add({
            'symbol': symbol,
            'stockName': symbol,
            'exchange': 'NSE',
            'quantity': quantity,
            'averageBuyPrice': price,
            'totalInvested': totalValue,
            'currentPrice': price,
            'currentValue': totalValue,
            'unrealizedPnL': 0.0,
            'pnlPercent': 0.0
          });
        }
      } else {
        _walletBalance += totalValue;
        final list = _portfolio!['holdings'] as List;
        final idx = list.indexWhere((h) => h['symbol'] == symbol);
        final held = list[idx]['quantity'];
        if (held == quantity) {
          list.removeAt(idx);
        } else {
          list[idx]['quantity'] -= quantity;
          list[idx]['totalInvested'] = list[idx]['quantity'] * list[idx]['averageBuyPrice'];
        }
      }

      _trades.insert(0, {
        'symbol': symbol,
        'type': type,
        'quantity': quantity,
        'price': price,
        'totalValue': totalValue,
        'createdAt': DateTime.now().toIso8601String()
      });

      _portfolio!['totalInvested'] = (_portfolio!['holdings'] as List).fold<double>(0.0, (sum, h) => sum + h['totalInvested']);
      _portfolio!['totalCurrentValue'] = (_portfolio!['holdings'] as List).fold<double>(0.0, (sum, h) => sum + (h['quantity'] * price));
      _portfolio!['totalUnrealized'] = _portfolio!['totalCurrentValue'] - _portfolio!['totalInvested'];

      notifyListeners();
      return {'success': true, 'message': 'Offline trade simulated!'};
    }

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/trade'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': _userId,
          'symbol': symbol,
          'type': type,
          'quantity': quantity,
        }),
      ).timeout(const Duration(seconds: 5));

      final data = json.decode(res.body);
      if (res.statusCode == 201) {
        _walletBalance = (data['newBalance'] as num).toDouble();
        await fetchPortfolio();
        await fetchTradeHistory();
        notifyListeners();
        return {'success': true, 'message': data['message'] ?? 'Order executed successfully'};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Order execution failed'};
      }
    } catch (e) {
      debugPrint("Error executing trade: $e");
      return {'success': false, 'error': 'Network timeout or connection refused'};
    }
  }
}

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarketProvider>(context);

    final List<Widget> tabs = [
      const MarketDashboardTab(),
      const PortfolioDashboardTab(),
      AIMentorTab(provider: provider),
      const AlertsManagerTab(),
      const TradeHistoryTab(),
    ];

    return Scaffold(
      body: SafeArea(
        child: tabs[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.gainGreen,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Markets',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'AI Mentor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
            label: 'My Rules',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

// ----------------- MARKETS VIEW -----------------
class MarketDashboardTab extends StatefulWidget {
  const MarketDashboardTab({super.key});

  @override
  State<MarketDashboardTab> createState() => _MarketDashboardTabState();
}

class _MarketDashboardTabState extends State<MarketDashboardTab> {
  String _activeSubTab = 'WATCHLIST'; // 'WATCHLIST', 'SCANNERS', 'SECTORS'

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarketProvider>(context);

    return Column(
      children: [
        _buildHeader(context, provider),
        if (provider.errorMessage.isNotEmpty) _buildErrorBanner(context, provider),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.fetchMarketData(),
            color: AppColors.gainGreen,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                const SizedBox(height: 16),
                _buildWalletSection(provider),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildSubTabButton('Watchlist', 'WATCHLIST'),
                    const SizedBox(width: 8),
                    _buildSubTabButton('Breakout Scanners', 'SCANNERS'),
                    const SizedBox(width: 8),
                    _buildSubTabButton('Sectoral Indices', 'SECTORS'),
                  ],
                ),
                const SizedBox(height: 16),
                if (_activeSubTab == 'WATCHLIST') ...[
                  _buildSectionTitle('Market Indices'),
                  const SizedBox(height: 10),
                  _buildIndicesGrid(provider),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Watchlist (NSE)'),
                  const SizedBox(height: 10),
                  _buildWatchList(provider),
                ] else if (_activeSubTab == 'SCANNERS') ...[
                  MarketScannersTab(provider: provider),
                ] else if (_activeSubTab == 'SECTORS') ...[
                  MarketSectorsTab(provider: provider),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubTabButton(String label, String tabKey) {
    final active = _activeSubTab == tabKey;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (val) {
        if (val) setState(() => _activeSubTab = tabKey);
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.gainGreen.withOpacity(0.15),
      labelStyle: TextStyle(
        color: active ? AppColors.gainGreen : AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      side: BorderSide(
        color: active ? AppColors.gainGreen : Colors.white.withOpacity(0.05),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MarketProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: AppColors.gainGreen, size: 28),
              const SizedBox(width: 8),
              Text(
                'TradeMentor',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.textSecondary),
            onPressed: () => _showSettingsDialog(context, provider),
          )
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, MarketProvider provider) {
    return Container(
      width: double.infinity,
      color: AppColors.lossRed.withOpacity(0.25),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.lossRed, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.errorMessage,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => _showSettingsDialog(context, provider),
            child: const Text('Configure IP', style: TextStyle(color: AppColors.gainGreen, fontSize: 12)),
          )
        ],
      ),
    );
  }

  Widget _buildWalletSection(MarketProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.surface.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Simulated Wallet Balance',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${provider.walletBalance.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.gainGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet, color: AppColors.gainGreen),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildIndicesGrid(MarketProvider provider) {
    if (provider.indices.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(color: AppColors.gainGreen)),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: provider.indices.length,
      itemBuilder: (context, index) {
        final idx = provider.indices[index];
        final history = provider.priceHistory[idx['symbol']] ?? [];
        final pChange = (idx['pChange'] as num).toDouble();
        final isPositive = pChange >= 0;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    idx['symbol'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isPositive ? AppColors.gainGreen : AppColors.lossRed).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${isPositive ? "+" : ""}${pChange.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? AppColors.gainGreen : AppColors.lossRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '₹${(idx['currentPrice'] as num).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: MiniSparkline(
                  history: history,
                  isPositive: isPositive,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWatchList(MarketProvider provider) {
    if (provider.stocks.isEmpty && provider.isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator(color: AppColors.gainGreen)),
      );
    }
    if (provider.stocks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Text(
            'No stocks loaded. Ensure server is connected.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.stocks.length,
      separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.04)),
      itemBuilder: (context, index) {
        final stock = provider.stocks[index];
        final pChange = (stock['pChange'] as num).toDouble();
        final isPositive = pChange >= 0;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          onTap: () => _showStockActionsSheet(context, stock, provider),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Center(
              child: Text(
                stock['symbol'].substring(0, 2),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.gainGreen),
              ),
            ),
          ),
          title: Text(
            stock['symbol'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(
            stock['name'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '₹${(stock['currentPrice'] as num).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: isPositive ? AppColors.gainGreen : AppColors.lossRed,
                    size: 16,
                  ),
                  Text(
                    '${isPositive ? "+" : ""}${pChange.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? AppColors.gainGreen : AppColors.lossRed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSettingsDialog(BuildContext context, MarketProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              const Icon(Icons.settings, color: AppColors.gainGreen),
              const SizedBox(width: 8),
              Text(
                'Platform Settings',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section 1: User profile details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User Account Profile',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Name:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          Text(provider.userName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Email:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          Flexible(child: Text(provider.userEmail.isNotEmpty ? provider.userEmail : 'demo@tradementor.com', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Wallet Balance:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          Text('₹${provider.walletBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gainGreen)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Section 2: Server URL configuration
                const Text(
                  'Backend Server URL',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                _ServerUrlField(provider: provider),
                const SizedBox(height: 16),
                
                // Section 3: AI Risk Profile settings
                const Text(
                  'AI Advisor Risk Model',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildRiskOption(context, 'low', 'Low', provider, setState),
                    const SizedBox(width: 6),
                    _buildRiskOption(context, 'moderate', 'Moderate', provider, setState),
                    const SizedBox(width: 6),
                    _buildRiskOption(context, 'high', 'High', provider, setState),
                  ],
                ),
                const SizedBox(height: 20),

                // Section 4: Logout button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      provider.setLoggedIn(false);
                      provider.setScreen('SPLASH');
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logged out. Onboarding reset.'), backgroundColor: Colors.blue),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lossRed.withOpacity(0.12),
                      foregroundColor: AppColors.lossRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.lossRed, width: 0.5),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, size: 16),
                        SizedBox(width: 8),
                        Text('Log Out & Reset Onboarding', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close', style: TextStyle(color: Colors.white60)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskOption(BuildContext context, String id, String label, MarketProvider provider, StateSetter setState) {
    final active = provider.riskProfile == id;
    return Expanded(
      child: InkWell(
        onTap: () {
          provider.setRiskProfile(id);
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Advisor risk model set to ${label.toUpperCase()}'), duration: const Duration(seconds: 1)),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.gainGreen.withOpacity(0.12) : AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? AppColors.gainGreen : Colors.white.withOpacity(0.04),
              width: active ? 1 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: active ? AppColors.gainGreen : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStockActionsSheet(BuildContext context, Map<String, dynamic> stock, MarketProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockDetailsScreen(stock: stock, provider: provider),
      ),
    );
  }
}

void showServerConfigDialog(BuildContext context, MarketProvider provider) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          const Icon(Icons.dns, color: AppColors.gainGreen),
          const SizedBox(width: 8),
          Text(
            'Server Configuration',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Configure the Express API backend address. If running on a physical Android device, enter your computer\'s local network IP address (e.g. http://192.168.1.15:5000) instead of localhost.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _ServerUrlField(provider: provider),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    ),
  );
}

// Server URL field widget used in Settings dialog
class _ServerUrlField extends StatefulWidget {
  final MarketProvider provider;
  const _ServerUrlField({required this.provider});
  @override
  State<_ServerUrlField> createState() => _ServerUrlFieldState();
}

class _ServerUrlFieldState extends State<_ServerUrlField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.provider.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your PC\'s local IP address',
            style: TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.url,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. http://192.168.1.5:5000',
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.gainGreen),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () {
                final newUrl = _controller.text.trim();
                if (newUrl.isNotEmpty) {
                  widget.provider.updateBaseUrl(newUrl);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Server URL updated to $newUrl'),
                      backgroundColor: AppColors.gainGreen.withOpacity(0.8),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Save & Reconnect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gainGreen.withOpacity(0.15),
                foregroundColor: AppColors.gainGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.gainGreen, width: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------- ALERTS VIEW -----------------
class AlertsManagerTab extends StatefulWidget {
  const AlertsManagerTab({super.key});

  @override
  State<AlertsManagerTab> createState() => _AlertsManagerTabState();
}

class _AlertsManagerTabState extends State<AlertsManagerTab> {
  String _activeSubTab = 'ACTIVE'; // 'ACTIVE', 'TRIGGERED', 'WIZARD'

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarketProvider>(context);
    final activeAlerts = provider.alerts.where((a) => a['isTriggered'] == false).toList();
    final triggeredAlerts = provider.alerts.where((a) => a['isTriggered'] == true).toList();

    return Column(
      children: [
        _buildHeader(provider),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              _buildSubTabButton('Active Rules (${activeAlerts.length})', 'ACTIVE'),
              const SizedBox(width: 8),
              _buildSubTabButton('Fired Logs (${triggeredAlerts.length})', 'TRIGGERED'),
              const SizedBox(width: 8),
              _buildSubTabButton('Rule Wizard', 'WIZARD'),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.fetchUserAlerts(),
            color: AppColors.gainGreen,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                if (_activeSubTab == 'ACTIVE') ...[
                  if (activeAlerts.isEmpty)
                    _buildEmptyState('No active alerts pending.')
                  else
                    _buildAlertsList(activeAlerts, provider),
                ] else if (_activeSubTab == 'TRIGGERED') ...[
                  if (triggeredAlerts.isEmpty)
                    _buildEmptyState('No triggered rule history logs.')
                  else
                    _buildAlertsList(triggeredAlerts, provider),
                ] else if (_activeSubTab == 'WIZARD') ...[
                  RuleWizardView(provider: provider),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubTabButton(String label, String tabKey) {
    final active = _activeSubTab == tabKey;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (val) {
        if (val) setState(() => _activeSubTab = tabKey);
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.gainGreen.withOpacity(0.15),
      labelStyle: TextStyle(
        color: active ? AppColors.gainGreen : AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      side: BorderSide(
        color: active ? AppColors.gainGreen : Colors.white.withOpacity(0.05),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Column(
          children: [
            const Icon(Icons.notifications_none, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(msg, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MarketProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: AppColors.gainGreen, size: 28),
              const SizedBox(width: 8),
              Text(
                'My Active Rules',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () => provider.fetchUserAlerts(),
          )
        ],
      ),
    );
  }

  Widget _buildCriteriaBadge(String criteria) {
    String text = criteria;
    Color badgeColor = Colors.blueAccent;
    if (criteria == 'GREATER_THAN') {
      text = '>=';
      badgeColor = AppColors.gainGreen;
    } else if (criteria == 'LESS_THAN') {
      text = '<=';
      badgeColor = AppColors.lossRed;
    } else if (criteria == 'STOP_LOSS') {
      text = 'Stop Loss';
      badgeColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
      ),
    );
  }

  Widget _buildAlertsList(List<dynamic> list, MarketProvider provider) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final alert = list[index];
        final isTriggered = alert['isTriggered'] == true;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        alert['symbol'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      _buildCriteriaBadge(alert['criteria']),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Target Price: ₹${(alert['targetPrice'] as num).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  if (isTriggered && alert['triggeredAt'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Triggered: ${DateTime.parse(alert['triggeredAt']).toLocal().toString().substring(0, 19)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ]
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isTriggered ? AppColors.gainGreen : Colors.orangeAccent).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isTriggered ? 'Fired' : 'Pending',
                      style: TextStyle(
                        color: isTriggered ? AppColors.gainGreen : Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  if (!isTriggered) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColors.lossRed, size: 18),
                      onPressed: () async {
                        final success = await provider.deleteAlert(alert['_id']);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Rule deleted successfully!'), backgroundColor: AppColors.gainGreen),
                          );
                        }
                      },
                    ),
                  ]
                ],
              )
            ],
          ),
        );
      },
    );
  }
}

// ----------------- PORTFOLIO VIEW -----------------
class PortfolioDashboardTab extends StatefulWidget {
  const PortfolioDashboardTab({super.key});

  @override
  State<PortfolioDashboardTab> createState() => _PortfolioDashboardTabState();
}

class _PortfolioDashboardTabState extends State<PortfolioDashboardTab> {
  String _activeSubTab = 'HOLDINGS'; // 'HOLDINGS', 'WALLET', 'TAX'

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarketProvider>(context);
    final portfolio = provider.portfolio;

    return Column(
      children: [
        _buildHeader(provider),
        if (provider.errorMessage.isNotEmpty) _buildErrorBanner(context, provider),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.fetchPortfolio(),
            color: AppColors.gainGreen,
            child: portfolio == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.gainGreen))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildSubTabButton('Holdings', 'HOLDINGS'),
                          const SizedBox(width: 8),
                          _buildSubTabButton('Wallet Manager', 'WALLET'),
                          const SizedBox(width: 8),
                          _buildSubTabButton('Capital Gains Tax', 'TAX'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_activeSubTab == 'HOLDINGS') ...[
                        _buildSummaryGrid(portfolio),
                        const SizedBox(height: 24),
                        _buildSectionTitle('My Holdings'),
                        const SizedBox(height: 12),
                        if (portfolio['holdings'] == null || (portfolio['holdings'] as List).isEmpty)
                          _buildEmptyState()
                        else
                          _buildHoldingsList(context, portfolio['holdings'], provider),
                      ] else if (_activeSubTab == 'WALLET') ...[
                        WalletManagerView(provider: provider),
                      ] else if (_activeSubTab == 'TAX') ...[
                        TaxReportView(provider: provider),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubTabButton(String label, String tabKey) {
    final active = _activeSubTab == tabKey;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (val) {
        if (val) setState(() => _activeSubTab = tabKey);
      },
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.gainGreen.withOpacity(0.15),
      labelStyle: TextStyle(
        color: active ? AppColors.gainGreen : AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      side: BorderSide(
        color: active ? AppColors.gainGreen : Colors.white.withOpacity(0.05),
      ),
    );
  }

  Widget _buildHeader(MarketProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart, color: AppColors.gainGreen, size: 28),
              const SizedBox(width: 8),
              Text(
                'My Portfolio',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () => provider.fetchPortfolio(),
          )
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context, MarketProvider provider) {
    return Container(
      width: double.infinity,
      color: AppColors.lossRed.withOpacity(0.25),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.lossRed, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              provider.errorMessage,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(Map<String, dynamic> portfolio) {
    final double invested = (portfolio['totalInvested'] as num?)?.toDouble() ?? 0.0;
    final double current = (portfolio['totalCurrentValue'] as num?)?.toDouble() ?? 0.0;
    final double unrealized = (portfolio['totalUnrealized'] as num?)?.toDouble() ?? 0.0;
    final double realized = (portfolio['totalRealizedPnL'] as num?)?.toDouble() ?? 0.0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildSummaryCard('Total Invested', '₹${invested.toStringAsFixed(2)}', Colors.white60),
        _buildSummaryCard('Current Value', '₹${current.toStringAsFixed(2)}', Colors.white),
        _buildSummaryCard(
          'Unrealized P&L',
          '${unrealized >= 0 ? "+" : ""}₹${unrealized.toStringAsFixed(2)}',
          unrealized >= 0 ? AppColors.gainGreen : AppColors.lossRed,
        ),
        _buildSummaryCard(
          'Realized P&L',
          '${realized >= 0 ? "+" : ""}₹${realized.toStringAsFixed(2)}',
          realized >= 0 ? AppColors.gainGreen : AppColors.lossRed,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pie_chart_outline, size: 48, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text(
            'No holdings in your portfolio yet',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 6),
          Text(
            'Buy simulated shares from the Markets tab to start your paper trading journey.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldingsList(BuildContext context, List<dynamic> holdings, MarketProvider provider) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: holdings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final h = holdings[index];
        final qty = h['quantity'] as int;
        final avgBuy = (h['averageBuyPrice'] as num).toDouble();
        final currentPrice = (h['currentPrice'] as num).toDouble();
        final invested = (h['totalInvested'] as num).toDouble();
        final currentValue = (h['currentValue'] as num).toDouble();
        final pnl = (h['unrealizedPnL'] as num).toDouble();
        final pnlPct = (h['pnlPercent'] as num).toDouble();
        final isPositive = pnl >= 0;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h['symbol'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${h['exchange']} · $qty shares',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${currentValue.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                            color: isPositive ? AppColors.gainGreen : AppColors.lossRed,
                            size: 16,
                          ),
                          Text(
                            '${isPositive ? "+" : ""}₹${pnl.abs().toStringAsFixed(2)} (${isPositive ? "+" : ""}${pnlPct.toStringAsFixed(2)}%)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPositive ? AppColors.gainGreen : AppColors.lossRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10.0),
                child: Divider(color: Colors.white12, height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Avg Buy Price', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text('₹${avgBuy.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Market Price', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text('₹${currentPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Invested', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      const SizedBox(height: 2),
                      Text('₹${invested.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      final stock = provider.stocks.firstWhere(
                        (s) => s['symbol'] == h['symbol'],
                        orElse: () => {
                          'symbol': h['symbol'],
                          'name': h['stockName'] ?? h['symbol'],
                          'exchange': h['exchange'],
                          'currentPrice': currentPrice,
                          'pChange': 0.0,
                        },
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StockDetailsScreen(stock: stock, provider: provider),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lossRed.withOpacity(0.15),
                      foregroundColor: AppColors.lossRed,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      minimumSize: const Size(60, 32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Sell', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ----------------- TRADE HISTORY VIEW -----------------
class TradeHistoryTab extends StatelessWidget {
  const TradeHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<MarketProvider>(context);
    final trades = provider.trades;

    return Column(
      children: [
        _buildHeader(provider),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.fetchTradeHistory(),
            color: AppColors.gainGreen,
            child: trades.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: trades.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final t = trades[index];
                      final isBuy = t['type'] == 'BUY';
                      final qty = t['quantity'] as int;
                      final price = (t['price'] as num).toDouble();
                      final totalValue = (t['totalValue'] as num).toDouble();
                      final realizedPnL = t['realizedPnL'] != null ? (t['realizedPnL'] as num).toDouble() : null;

                      String dateStr = '';
                      try {
                        dateStr = DateTime.parse(t['createdAt']).toLocal().toString().substring(5, 16);
                      } catch (_) {
                        dateStr = '';
                      }

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (isBuy ? AppColors.gainGreen : AppColors.lossRed).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    t['type'],
                                    style: TextStyle(
                                      color: isBuy ? AppColors.gainGreen : AppColors.lossRed,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t['symbol'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$qty shares @ ₹${price.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                  Text(
                                  '₹${totalValue.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                if (realizedPnL != null)
                                  Text(
                                    '${realizedPnL >= 0 ? "+" : ""}₹${realizedPnL.toStringAsFixed(2)} P&L',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: realizedPnL >= 0 ? AppColors.gainGreen : AppColors.lossRed,
                                    ),
                                  )
                                else
                                  Text(
                                    dateStr,
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(MarketProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: AppColors.gainGreen, size: 28),
              const SizedBox(width: 8),
              Text(
                'Trade Ledger',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () => provider.fetchTradeHistory(),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: AppColors.textMuted),
          SizedBox(height: 16),
          Text(
            'No transactions recorded',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 6),
          Text(
            'Executed trades (BUY / SELL) will list here in historical order.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ----------------- SUB-COMPONENTS & DIALOGS -----------------
class MiniSparkline extends StatelessWidget {
  final List<double> history;
  final bool isPositive;

  const MiniSparkline({
    super.key,
    required this.history,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    if (history.length < 2) {
      return const SizedBox(
        height: 25,
        child: Center(
          child: Text('Analyzing...', style: TextStyle(color: AppColors.textMuted, fontSize: 8)),
        ),
      );
    }

    final minPrice = history.reduce((a, b) => a < b ? a : b);
    final maxPrice = history.reduce((a, b) => a > b ? a : b);

    final padding = (maxPrice - minPrice) * 0.05 == 0 ? 1.0 : (maxPrice - minPrice) * 0.05;

    List<FlSpot> spots = [];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), history[i]));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (history.length - 1).toDouble(),
        minY: minPrice - padding,
        maxY: maxPrice + padding,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: isPositive ? AppColors.gainGreen : AppColors.lossRed,
            barWidth: 2.0,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: (isPositive ? AppColors.gainGreen : AppColors.lossRed).withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}
