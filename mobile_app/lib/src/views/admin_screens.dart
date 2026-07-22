import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/state_providers.dart';
import '../widgets/glass_container.dart';
import '../services/api_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ADMIN CONTROL CENTER')),
      body: GridView.count(
        padding: const EdgeInsets.all(16.0),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: [
          _buildAdminMenuTile(context, Icons.speed, 'System Health', '/system-settings'),
          _buildAdminMenuTile(context, Icons.people, 'User Accounts', '/admin-users'),
          _buildAdminMenuTile(context, Icons.lock_open, 'Rules Monitor', '/admin-rules'),
          _buildAdminMenuTile(context, Icons.sports_esports, 'Market Simulator', '/mock-market-control'),
          _buildAdminMenuTile(context, Icons.analytics, 'Analytics', '/admin-analytics'),
          _buildAdminMenuTile(context, Icons.campaign, 'Alert Bulletins', '/admin-alerts'),
        ],
      ),
    );
  }

  Widget _buildAdminMenuTile(BuildContext context, IconData icon, String label, String route) {
    return InkWell(
      onTap: () => context.push(route),
      child: GlassContainer(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: AppTheme.darkAccent),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MANAGE ACCOUNTS')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('T1')),
              title: Text('trader1@gmail.com'),
              subtitle: Text('Rules: 4 | Portfolio Value: \$12,500'),
              trailing: Icon(Icons.lock_open, color: Colors.green),
            ),
          ),
          Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('T2')),
              title: Text('investor_prime@yahoo.com'),
              subtitle: Text('Rules: 10 | Portfolio Value: \$45,800'),
              trailing: Icon(Icons.lock_open, color: Colors.green),
            ),
          )
        ],
      ),
    );
  }
}

class AdminRulesScreen extends ConsumerWidget {
  const AdminRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(rulesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('MONITOR ALL RULES')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: rules.length,
        itemBuilder: (context, idx) {
          final r = rules[idx];
          return Card(
            child: ListTile(
              title: Text(r.name),
              subtitle: Text('Ticker: ${r.ticker} | Active: ${r.isActive}'),
              trailing: const Icon(Icons.verified, color: Colors.blue),
            ),
          );
        },
      ),
    );
  }
}

class AdminAlertsScreen extends StatelessWidget {
  const AdminAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EMIT SYSTEM BROADCAST')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const TextField(
                decoration: InputDecoration(labelText: 'Bulletin Header', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(labelText: 'Body text content', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('System announcement broadcast completed!')),
                  );
                  context.pop();
                },
                child: const Text('Broadcast Bulletin Notification'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SYSTEM ANALYTICS')),
      body: const Center(
        child: Text('Live metrics reports compiling.'),
      ),
    );
  }
}

class SystemSettingsScreen extends StatelessWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SYSTEM CONFIGURATIONS')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              title: Text('API Service Gateway'),
              subtitle: Text('http://localhost:5000/api'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('Active WebSocket Channels'),
              subtitle: Text('ws://localhost:5000/ws'),
            ),
          )
        ],
      ),
    );
  }
}

class MockMarketControlScreen extends StatefulWidget {
  const MockMarketControlScreen({super.key});

  @override
  State<MockMarketControlScreen> createState() => _MockMarketControlScreenState();
}

class _MockMarketControlScreenState extends State<MockMarketControlScreen> {
  String selectedTicker = 'TSLA';
  double mockPrice = 175.20;
  double mockRsi = 35.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MARKET OVERRIDES SIMULATOR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Configure Overrides',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Override stock metrics instantly. Use this to drag prices/RSI down or up and force rule fires instantly for live demos.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              const Text('Select Target Asset', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedTicker,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: ['AAPL', 'TSLA', 'MSFT', 'GOOG', 'RELIANCE', 'INFY']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedTicker = val;
                      if (val == 'TSLA') {
                        mockPrice = 175.20;
                        mockRsi = 35.0;
                      } else if (val == 'AAPL') {
                        mockPrice = 180.50;
                        mockRsi = 45.0;
                      } else {
                        mockPrice = 500.0;
                        mockRsi = 50.0;
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              Text('Override Price: \$${mockPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Slider(
                value: mockPrice,
                min: 50.0,
                max: 3000.0,
                onChanged: (val) {
                  setState(() => mockPrice = val);
                },
              ),
              const SizedBox(height: 16),
              Text('Override RSI Oscillator: ${mockRsi.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Slider(
                value: mockRsi,
                min: 5.0,
                max: 95.0,
                onChanged: (val) {
                  setState(() => mockRsi = val);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final success = await ApiService.instance.adminMockUpdateStock(
                    selectedTicker,
                    mockPrice,
                    mockRsi,
                  );
                  if (!mounted) return;
                  if (success) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Market mock override applied successfully! $selectedTicker updated.')),
                    );
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Simulator server update failed. Applied locally.')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('APPLY OVERRIDES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
