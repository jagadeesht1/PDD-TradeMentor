import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/state_providers.dart';
import '../widgets/glass_container.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('PORTFOLIO MANAGER')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassContainer(
              child: Column(
                children: [
                  const Text('PORTFOLIO DIVERSIFICATION', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSectorBadge('Tech', Colors.blue, 70),
                      _buildSectorBadge('Auto', Colors.red, 20),
                      _buildSectorBadge('Finance', Colors.green, 10),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.list),
                    label: const Text('My Holdings'),
                    onPressed: () => context.push('/holdings'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.flash_on),
                    label: const Text('Intraday Positions'),
                    onPressed: () => context.push('/positions'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('Analytics'),
                    onPressed: () => context.push('/performance-analytics'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.business),
                    label: const Text('Corporate Actions'),
                    onPressed: () => context.push('/corporate-actions'),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSectorBadge(String label, Color color, int percent) {
    return Column(
      children: [
        CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 24, child: Text('$percent%', style: TextStyle(color: color, fontWeight: FontWeight.bold))),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class HoldingsScreen extends ConsumerWidget {
  const HoldingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holdings = ref.watch(portfolioProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('INVESTMENT HOLDINGS')),
      body: holdings.isEmpty
          ? const Center(child: Text('You have no open investment holdings.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: holdings.length,
              itemBuilder: (context, idx) {
                final h = holdings[idx];
                final isProfit = h.profitOrLoss >= 0;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(h.ticker, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text(
                              '${isProfit ? '+' : ''}\$${h.profitOrLoss.toStringAsFixed(2)} (${isProfit ? '+' : ''}${h.profitOrLossPercent.toStringAsFixed(2)}%)',
                              style: TextStyle(color: isProfit ? AppTheme.bullColor : AppTheme.bearColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Shares: ${h.sharesCount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.grey)),
                            Text('Avg Cost: \$${h.averageBuyPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
                            Text('Current: \$${h.currentPrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class PositionsScreen extends ConsumerWidget {
  const PositionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('INTRADAY POSITIONS')),
      body: const Center(
        child: Text('No active intraday positions. Intraday positions close daily at 15:30.'),
      ),
    );
  }
}

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('ORDERS HISTORY LOG')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: AppTheme.bullColor),
              title: Text('AAPL BUY EXECUTION'),
              subtitle: Text('10 Shares @ \$175.00'),
              trailing: Text('COMPLETED', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: AppTheme.bullColor),
              title: Text('TSLA BUY EXECUTION'),
              subtitle: Text('5 Shares @ \$180.00'),
              trailing: Text('COMPLETED', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}

class PerformanceAnalyticsScreen extends StatelessWidget {
  const PerformanceAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PORTFOLIO PERFORMANCE')),
      body: const Center(
        child: Text('Visual analytics summary modules will load statistics dynamically.'),
      ),
    );
  }
}

class CorporateActionsScreen extends StatelessWidget {
  const CorporateActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CORPORATE NOTICES')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              title: Text('AAPL Cash Dividend declared'),
              subtitle: Text('Payout: \$0.24 per share | Ex-Date: 2026-07-01'),
              trailing: Icon(Icons.monetization_on_outlined, color: Colors.green),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('TSLA Stock Split notice'),
              subtitle: Text('Split ratio: 3:1 splits scheduled | Effective: 2026-08-15'),
              trailing: Icon(Icons.call_split, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
