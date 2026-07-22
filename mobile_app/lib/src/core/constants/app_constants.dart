class AppConstants {
  // Local network configurations for development/demos
  static const String baseRestUrl = 'http://localhost:5000/api';
  static const String baseWsUrl = 'ws://localhost:5000/ws';

  // Standard Mock Trading Assets list
  static const List<Map<String, String>> tickersList = [
    {'symbol': 'AAPL', 'name': 'Apple Inc.', 'sector': 'Technology'},
    {'symbol': 'TSLA', 'name': 'Tesla Inc.', 'sector': 'Automotive'},
    {'symbol': 'MSFT', 'name': 'Microsoft Corp.', 'sector': 'Technology'},
    {'symbol': 'GOOG', 'name': 'Alphabet Inc.', 'sector': 'Technology'},
    {'symbol': 'RELIANCE', 'name': 'Reliance Industries', 'sector': 'Conglomerate'},
    {'symbol': 'INFY', 'name': 'Infosys Ltd.', 'sector': 'Technology'},
  ];

  // User Risk Parameters definitions
  static const List<String> riskLevels = ['Conservative', 'Moderate', 'Aggressive'];

  // Routing navigation path names
  static const String splashPath = '/';
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String otpPath = '/verify-otp';
  static const String forgotPasswordPath = '/forgot-password';
  static const String profileSetupPath = '/profile-setup';
  static const String dashboardPath = '/dashboard';
}
