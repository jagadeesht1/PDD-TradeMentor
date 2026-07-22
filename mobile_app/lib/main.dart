import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'src/core/router/app_router.dart';
import 'src/core/theme/app_theme.dart';
import 'src/providers/state_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local database storage adapters
  await Hive.initFlutter();
  await Hive.openBox('user_settings');
  await Hive.openBox('chat_history');

  runApp(
    const ProviderScope(
      child: TradeMentorApp(),
    ),
  );
}

class TradeMentorApp extends ConsumerWidget {
  const TradeMentorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = appRouter;
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'TradeMentor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
