import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../models/stock_model.dart';
import '../providers/state_providers.dart';
import '../widgets/glass_container.dart';

class RuleBuilderScreen extends ConsumerStatefulWidget {
  const RuleBuilderScreen({super.key});

  @override
  ConsumerState<RuleBuilderScreen> createState() => _RuleBuilderScreenState();
}

class _RuleBuilderScreenState extends ConsumerState<RuleBuilderScreen> {
  final nameCtrl = TextEditingController(text: 'My Custom RSI Alert');
  String selectedTicker = 'AAPL';
  String selectedIndicator = 'RSI';
  String selectedComparison = 'LESS_THAN';
  final thresholdCtrl = TextEditingController(text: '30.0');
  String selectedOp = 'AND';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NEW RULE BUILDER')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Strategy Custom Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Target Stock Ticker', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedTicker,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: ['AAPL', 'TSLA', 'MSFT', 'GOOG', 'RELIANCE', 'INFY']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedTicker = val);
                },
              ),
              const SizedBox(height: 16),
              const Text('Oscillator Indicator Metric', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedIndicator,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: ['Price', 'RSI', 'Volume']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedIndicator = val);
                },
              ),
              const SizedBox(height: 16),
              const Text('Conditional Evaluation', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedComparison,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: ['LESS_THAN', 'GREATER_THAN']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => selectedComparison = val);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: thresholdCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Threshold Limit Value', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final conditions = [
                    ConditionModel(
                      indicator: selectedIndicator,
                      comparison: selectedComparison,
                      thresholdValue: double.tryParse(thresholdCtrl.text) ?? 30.0,
                    )
                  ];
                  ref.read(rulesListProvider.notifier).addNewRule(
                    nameCtrl.text,
                    selectedTicker,
                    conditions,
                    selectedOp,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alert strategy successfully registered!')),
                  );
                  context.go('/rules-dashboard');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('SAVE STRATEGY RULE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push('/rule-templates'),
                child: const Text('View Strategy Templates'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class RulesDashboardScreen extends ConsumerWidget {
  const RulesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(rulesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ACTIVE STRATEGIES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/rule-builder'),
          )
        ],
      ),
      body: rules.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No strategies created yet.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.push('/rule-builder'),
                    child: const Text('Create Custom Rule'),
                  )
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: rules.length,
              itemBuilder: (context, idx) {
                final rule = rules[idx];
                return Card(
                  child: ListTile(
                    title: Text(rule.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Target Ticker: ${rule.ticker} | Conditions: ${rule.conditions.length}'),
                    leading: Switch(
                      value: rule.isActive,
                      onChanged: (_) => ref.read(rulesListProvider.notifier).toggleRule(rule.id),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => ref.read(rulesListProvider.notifier).removeRule(rule.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class AlertHistoryScreen extends ConsumerWidget {
  const AlertHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ALERTS HISTORY LOG'),
        actions: [
          TextButton(
            onPressed: () => ref.read(alertsLogProvider.notifier).clearAll(),
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(alertsLogProvider.notifier).refreshAlerts(),
        child: alerts.isEmpty
            ? const Center(child: Text('No alert signals fired recently.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: alerts.length,
                itemBuilder: (context, idx) {
                  final alert = alerts[idx];
                  return Card(
                    child: ListTile(
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(alert.ticker, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            alert.createdAt.split('T').first,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(alert.message),
                      ),
                      leading: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => context.push('/alert-detail/${alert.id}'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class RuleTemplateScreen extends ConsumerWidget {
  const RuleTemplateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = [
      {'name': 'RSI Oversold Bounce', 'ticker': 'TSLA', 'indicator': 'RSI', 'comp': 'LESS_THAN', 'val': 30.0},
      {'name': 'Golden Price Breakout', 'ticker': 'AAPL', 'indicator': 'Price', 'comp': 'GREATER_THAN', 'val': 190.0},
      {'name': 'Volume Spike Tracker', 'ticker': 'MSFT', 'indicator': 'Volume', 'comp': 'GREATER_THAN', 'val': 2500000.0},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('STRATEGY TEMPLATES')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: templates.length,
        separatorBuilder: (c, i) => const SizedBox(height: 12),
        itemBuilder: (context, idx) {
          final t = templates[idx];
          return Card(
            child: ListTile(
              title: Text(t['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('If ${t['indicator']} is ${t['comp']} than ${t['val']} on ${t['ticker']}'),
              trailing: const Icon(Icons.add_circle_outline, color: AppTheme.darkAccent),
              onTap: () {
                ref.read(rulesListProvider.notifier).addNewRule(
                  t['name'] as String,
                  t['ticker'] as String,
                  [ConditionModel(indicator: t['indicator'] as String, comparison: t['comp'] as String, thresholdValue: t['val'] as double)],
                  'AND',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Template "${t['name']}" applied and saved!')),
                );
                context.go('/rules-dashboard');
              },
            ),
          );
        },
      ),
    );
  }
}

class TriggeredAlertDetailScreen extends ConsumerWidget {
  final String alertId;

  const TriggeredAlertDetailScreen({super.key, required this.alertId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsLogProvider);
    final alert = alerts.firstWhere((a) => a.id == alertId, orElse: () => alerts.first);

    return Scaffold(
      appBar: AppBar(title: const Text('ALERT SIGNAL ANALYSIS')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(alert.ruleName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Ticker Asset: ${alert.ticker}', style: const TextStyle(color: AppTheme.darkAccent, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Trigger Price:'),
                  Text('\$${alert.triggerPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Signal Details:', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 6),
              Text(alert.message, style: const TextStyle(fontSize: 14, height: 1.4)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.push('/stock-details/${alert.ticker}'),
                child: const Text('View Real-Time Asset Charts'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class BacktestingScreen extends StatelessWidget {
  const BacktestingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('STRATEGY BACKTESTING')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Backtest Strategy Parameters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(title: Text('Historical Data range'), subtitle: Text('Last 30 Days (Daily tick resolution)')),
                    ListTile(title: Text('Strategy Rule Target'), subtitle: Text('Tesla RSI Oversold Alert')),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const AlertDialog(
                    title: Text('Backtest Summary'),
                    content: Text('Simulating over 3,000 candle periods:\n\n- Win Rate: 64.2%\n- Max Drawdown: 8.5%\n- Recommendations fired: 14 signals'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.darkAccent),
              child: const Text('RUN HISTORICAL SIMULATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
