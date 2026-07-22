import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../models/stock_model.dart';
import '../providers/state_providers.dart';
import '../widgets/glass_container.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final stocksAsync = ref.watch(stocksListProvider);
    final portfolio = ref.watch(portfolioProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final currentTheme = ref.watch(themeModeProvider);

    // Listen to alertsLogProvider to show real-time snackbars
    ref.listen<List<AlertModel>>(alertsLogProvider, (previous, next) {
      if (previous != null && next.length > previous.length) {
        final newAlert = next.first;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(newAlert.ruleName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(newAlert.message, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.amber,
              onPressed: () => context.push('/alert-detail/${newAlert.id}'),
            ),
            backgroundColor: Colors.grey[900],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    });

    double totalInvested = portfolio.fold(0, (sum, item) => sum + item.investedAmount);
    double totalCurrent = portfolio.fold(0, (sum, item) => sum + item.currentAmount);
    double netPL = totalCurrent - totalInvested;
    double plPercent = totalInvested == 0 ? 0.0 : (netPL / totalInvested) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TRADEMENTOR'),
        actions: [
          IconButton(
            icon: Icon(currentTheme == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeNotifier.toggleTheme(),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            onPressed: () => context.push('/alert-history'),
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () => context.push('/admin-dashboard'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hello banner
            Text(
              'Welcome, ${auth.name ?? 'Trader'} 👋',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              'Risk Profile: ${auth.riskTolerance}  •  Plan: ${auth.subscriptionLevel}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Nifty/Sensex Ticker row
            const Row(
              children: [
                Expanded(
                  child: GlassContainer(
                    padding: EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NIFTY 50', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('22,042.15', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('+184.20 (+0.84%)', style: TextStyle(color: AppTheme.bullColor, fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GlassContainer(
                    padding: EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SENSEX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('72,526.40', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('+610.15 (+0.85%)', style: TextStyle(color: AppTheme.bullColor, fontSize: 12)),
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),

            // Portfolio summary Card
            GlassContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PORTFOLIO VALUE', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('\$${totalCurrent.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Invested Capital', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text('\$${totalInvested.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Total Profit/Loss', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(
                            '${netPL >= 0 ? '+' : ''}\$${netPL.toStringAsFixed(2)} (${netPL >= 0 ? '+' : ''}${plPercent.toStringAsFixed(2)}%)',
                            style: TextStyle(
                              color: netPL >= 0 ? AppTheme.bullColor : AppTheme.bearColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rapid actions grid
            const Text('RAPID TOOLS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.0,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                _buildActionTile(context, Icons.insights, 'Rule Builder', '/rule-builder'),
                _buildActionTile(context, Icons.list_alt, 'Watchlists', '/watchlist'),
                _buildActionTile(context, Icons.pie_chart, 'Holdings', '/holdings'),
                _buildActionTile(context, Icons.chat_bubble_outline, 'AI Assistant', '/chatbot'),
                _buildActionTile(context, Icons.show_chart, 'Markets', '/market-overview'),
                _buildActionTile(context, Icons.history, 'Orders', '/order-history'),
                _buildActionTile(context, Icons.school, 'Education', '/trading-education'),
                _buildActionTile(context, Icons.tune, 'Settings', '/settings'),
              ],
            ),
            const SizedBox(height: 24),

            // Top Ticker list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ACTIVE FEEDS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => context.push('/market-overview'),
                  child: const Text('See All'),
                )
              ],
            ),
            stocksAsync.when(
              data: (stocks) => ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stocks.length > 3 ? 3 : stocks.length,
                separatorBuilder: (c, i) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final stock = stocks[idx];
                  final isBull = stock.change >= 0;
                  return InkWell(
                    onTap: () => context.push('/stock-details/${stock.ticker}'),
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(stock.ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(stock.companyName, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('\$${stock.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(
                                '${isBull ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                                style: TextStyle(color: isBull ? AppTheme.bullColor : AppTheme.bearColor, fontSize: 12),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Center(child: Text('Failed loading market feeds.')),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String label, String route) {
    return InkWell(
      onTap: () => context.push(route),
      child: GlassContainer(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: AppTheme.darkAccent),
            const SizedBox(height: 6),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class MarketOverviewScreen extends ConsumerWidget {
  const MarketOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocksAsync = ref.watch(stocksListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('MARKET WATCH')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Top Performing Assets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => context.push('/top-gainers-losers'),
                  child: const Text('Gainers & Losers'),
                )
              ],
            ),
            const SizedBox(height: 8),
            stocksAsync.when(
              data: (stocks) => ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: stocks.length,
                separatorBuilder: (c, i) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final s = stocks[idx];
                  final isBull = s.change >= 0;
                  return InkWell(
                    onTap: () => context.push('/stock-details/${s.ticker}'),
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(s.companyName, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('\$${s.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    'RSI: ${s.rsi.toStringAsFixed(1)}',
                                    style: TextStyle(fontSize: 11, color: s.rsi < 30 ? AppTheme.bullColor : (s.rsi > 70 ? AppTheme.bearColor : Colors.grey)),
                                  )
                                ],
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 70,
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                decoration: BoxDecoration(
                                  color: (isBull ? AppTheme.bullColor : AppTheme.bearColor).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${isBull ? '+' : ''}${s.changePercent.toStringAsFixed(2)}%',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: isBull ? AppTheme.bullColor : AppTheme.bearColor, fontWeight: FontWeight.bold, fontSize: 11),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Center(child: Text('Failed loading feeds')),
            ),
            const SizedBox(height: 24),
            const Text('Sector Performance Heatmap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => context.push('/sector-performance'),
              child: const SectorPerformanceWidget(),
            ),
          ],
        ),
      ),
    );
  }
}

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchSymbols = ref.watch(watchlistProvider);
    final stocksAsync = ref.watch(stocksListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MY WATCHLIST'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Quick dialog to add symbol
              showDialog(
                context: context,
                builder: (context) {
                  final textCtrl = TextEditingController();
                  return AlertDialog(
                    title: const Text('Add Ticker'),
                    content: TextField(
                      controller: textCtrl,
                      decoration: const InputDecoration(hintText: 'e.g. INFY'),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () {
                          if (textCtrl.text.isNotEmpty) {
                            ref.read(watchlistProvider.notifier).addTicker(textCtrl.text);
                          }
                          Navigator.pop(context);
                        },
                        child: const Text('Add'),
                      )
                    ],
                  );
                },
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: stocksAsync.when(
          data: (stocks) {
            final filtered = stocks.where((s) => watchSymbols.contains(s.ticker)).toList();
            if (filtered.isEmpty) {
              return const Center(child: Text('Watchlist is empty. Search and add symbols.'));
            }
            return ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (c, i) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final s = filtered[idx];
                final isBull = s.change >= 0;
                return Dismissible(
                  key: Key(s.ticker),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    ref.read(watchlistProvider.notifier).removeTicker(s.ticker);
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.red,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: InkWell(
                    onTap: () => context.push('/stock-details/${s.ticker}'),
                    child: GlassContainer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('\$${s.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '${isBull ? '+' : ''}${s.changePercent.toStringAsFixed(2)}%',
                                style: TextStyle(color: isBull ? AppTheme.bullColor : AppTheme.bearColor, fontSize: 13),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => const Center(child: Text('Failed loading watchlist data')),
        ),
      ),
    );
  }
}

class TopGainersLosersScreen extends ConsumerWidget {
  const TopGainersLosersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocksAsync = ref.watch(stocksListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('GAINERS & LOSERS')),
      body: stocksAsync.when(
        data: (stocks) {
          final sorted = List<StockModel>.from(stocks);
          sorted.sort((a, b) => b.changePercent.compareTo(a.changePercent));

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'TOP GAINERS'),
                    Tab(text: 'TOP LOSERS'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Gainers
                      ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: sorted.length,
                        itemBuilder: (context, idx) {
                          final s = sorted[idx];
                          return Card(
                            child: ListTile(
                              title: Text(s.ticker, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(s.companyName),
                              trailing: Text('+${s.changePercent.toStringAsFixed(2)}%', style: const TextStyle(color: AppTheme.bullColor, fontWeight: FontWeight.bold)),
                              onTap: () => context.push('/stock-details/${s.ticker}'),
                            ),
                          );
                        },
                      ),
                      // Losers
                      ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: sorted.length,
                        itemBuilder: (context, idx) {
                          final s = sorted[sorted.length - 1 - idx];
                          return Card(
                            child: ListTile(
                              title: Text(s.ticker, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(s.companyName),
                              trailing: Text('${s.changePercent.toStringAsFixed(2)}%', style: const TextStyle(color: AppTheme.bearColor, fontWeight: FontWeight.bold)),
                              onTap: () => context.push('/stock-details/${s.ticker}'),
                            ),
                          );
                        },
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const Center(child: Text('Failed to load indices')),
      ),
    );
  }
}

class SectorPerformanceScreen extends StatelessWidget {
  const SectorPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SECTORS INDEX')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SectorPerformanceWidget(),
      ),
    );
  }
}

class SectorPerformanceWidget extends StatelessWidget {
  const SectorPerformanceWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final list = [
      {'name': 'Technology (IT)', 'perf': 1.84, 'bullish': true},
      {'name': 'Automotive', 'perf': -0.42, 'bullish': false},
      {'name': 'Banking & Finance', 'perf': 1.15, 'bullish': true},
      {'name': 'Energy & Power', 'perf': 2.45, 'bullish': true},
      {'name': 'Pharmaceuticals', 'perf': -1.12, 'bullish': false},
    ];

    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: list.map((sector) {
          final isBull = sector['bullish'] as bool;
          final val = sector['perf'] as double;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(sector['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      '${isBull ? '+' : ''}${val.toStringAsFixed(2)}%',
                      style: TextStyle(color: isBull ? AppTheme.bullColor : AppTheme.bearColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (val.abs() / 3.0).clamp(0.1, 1.0),
                    backgroundColor: Colors.grey.withOpacity(0.1),
                    color: isBull ? AppTheme.bullColor : AppTheme.bearColor,
                    minHeight: 8,
                  ),
                )
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
