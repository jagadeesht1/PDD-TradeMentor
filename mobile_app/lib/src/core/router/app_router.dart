import 'package:go_router/go_router.dart';

// Import grouped screen modules
import '../../views/auth_screens.dart';
import '../../views/market_screens.dart';
import '../../views/stock_screens.dart';
import '../../views/rule_screens.dart';
import '../../views/portfolio_screens.dart';
import '../../views/chat_screens.dart';
import '../../views/settings_screens.dart';
import '../../views/admin_screens.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // --- Onboarding & Authentication ---
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/verify-otp', builder: (context, state) => const OtpVerificationScreen()),
    GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
    GoRoute(path: '/profile-setup', builder: (context, state) => const ProfileSetupScreen()),

    // --- Main Dashboard Navigation ---
    GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
    GoRoute(path: '/market-overview', builder: (context, state) => const MarketOverviewScreen()),
    GoRoute(path: '/watchlist', builder: (context, state) => const WatchlistScreen()),
    GoRoute(path: '/portfolio', builder: (context, state) => const PortfolioScreen()),
    GoRoute(path: '/chatbot', builder: (context, state) => const ChatbotScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),

    // --- Sub-Pages (Market, Sectors, Gainers) ---
    GoRoute(path: '/top-gainers-losers', builder: (context, state) => const TopGainersLosersScreen()),
    GoRoute(path: '/sector-performance', builder: (context, state) => const SectorPerformanceScreen()),

    // --- Stock Details & Trade Execution ---
    GoRoute(
      path: '/stock-details/:ticker',
      builder: (context, state) {
        final ticker = state.pathParameters['ticker'] ?? 'AAPL';
        return StockDetailsScreen(ticker: ticker);
      },
    ),
    GoRoute(
      path: '/technical-analysis/:ticker',
      builder: (context, state) {
        final ticker = state.pathParameters['ticker'] ?? 'AAPL';
        return TechnicalAnalysisScreen(ticker: ticker);
      },
    ),
    GoRoute(
      path: '/fundamental-analysis/:ticker',
      builder: (context, state) {
        final ticker = state.pathParameters['ticker'] ?? 'AAPL';
        return FundamentalAnalysisScreen(ticker: ticker);
      },
    ),
    GoRoute(
      path: '/chart-fullscreen/:ticker',
      builder: (context, state) {
        final ticker = state.pathParameters['ticker'] ?? 'AAPL';
        return ChartFullScreen(ticker: ticker);
      },
    ),
    GoRoute(
      path: '/technical-indicators/:ticker',
      builder: (context, state) {
        final ticker = state.pathParameters['ticker'] ?? 'AAPL';
        return TechnicalIndicatorsScreen(ticker: ticker);
      },
    ),
    GoRoute(
      path: '/order-entry/:ticker',
      builder: (context, state) {
        final ticker = state.pathParameters['ticker'] ?? 'AAPL';
        return OrderEntryScreen(ticker: ticker);
      },
    ),

    // --- Rule Builder Module ---
    GoRoute(path: '/rule-builder', builder: (context, state) => const RuleBuilderScreen()),
    GoRoute(path: '/rules-dashboard', builder: (context, state) => const RulesDashboardScreen()),
    GoRoute(path: '/alert-history', builder: (context, state) => const AlertHistoryScreen()),
    GoRoute(path: '/rule-templates', builder: (context, state) => const RuleTemplateScreen()),
    GoRoute(
      path: '/alert-detail/:alertId',
      builder: (context, state) {
        final alertId = state.pathParameters['alertId'] ?? '';
        return TriggeredAlertDetailScreen(alertId: alertId);
      },
    ),
    GoRoute(path: '/backtesting', builder: (context, state) => const BacktestingScreen()),

    // --- Portfolio Management ---
    GoRoute(path: '/holdings', builder: (context, state) => const HoldingsScreen()),
    GoRoute(path: '/positions', builder: (context, state) => const PositionsScreen()),
    GoRoute(path: '/order-history', builder: (context, state) => const OrderHistoryScreen()),
    GoRoute(path: '/performance-analytics', builder: (context, state) => const PerformanceAnalyticsScreen()),
    GoRoute(path: '/corporate-actions', builder: (context, state) => const CorporateActionsScreen()),

    // --- AI Chatbot & Education Modules ---
    GoRoute(path: '/chat-history', builder: (context, state) => const ChatHistoryScreen()),
    GoRoute(path: '/trading-education', builder: (context, state) => const TradingEducationHubScreen()),
    GoRoute(
      path: '/education-detail/:moduleId',
      builder: (context, state) {
        final moduleId = state.pathParameters['moduleId'] ?? '1';
        return EducationModuleDetailScreen(moduleId: moduleId);
      },
    ),
    GoRoute(path: '/risk-evaluator', builder: (context, state) => const RiskEvaluatorScreen()),
    GoRoute(path: '/stock-comparison', builder: (context, state) => const StockComparisonScreen()),

    // --- Profiles & Settings Sub-menus ---
    GoRoute(path: '/profile-management', builder: (context, state) => const ProfileManagementScreen()),
    GoRoute(path: '/security-settings', builder: (context, state) => const SecuritySettingsScreen()),
    GoRoute(path: '/notification-preferences', builder: (context, state) => const NotificationPreferencesScreen()),
    GoRoute(path: '/help-center', builder: (context, state) => const HelpCenterScreen()),
    GoRoute(path: '/subscription-plans', builder: (context, state) => const SubscriptionPlansScreen()),
    GoRoute(path: '/referral-program', builder: (context, state) => const ReferralProgramScreen()),
    GoRoute(path: '/privacy-policy', builder: (context, state) => const PrivacyPolicyScreen()),

    // --- Admin Dashboard Module ---
    GoRoute(path: '/admin-dashboard', builder: (context, state) => const AdminDashboardScreen()),
    GoRoute(path: '/admin-users', builder: (context, state) => const AdminUsersScreen()),
    GoRoute(path: '/admin-rules', builder: (context, state) => const AdminRulesScreen()),
    GoRoute(path: '/admin-alerts', builder: (context, state) => const AdminAlertsScreen()),
    GoRoute(path: '/admin-analytics', builder: (context, state) => const AdminAnalyticsScreen()),
    GoRoute(path: '/system-settings', builder: (context, state) => const SystemSettingsScreen()),
    GoRoute(path: '/mock-market-control', builder: (context, state) => const MockMarketControlScreen()),
  ],
);
