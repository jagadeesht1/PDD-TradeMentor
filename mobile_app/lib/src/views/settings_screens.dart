import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/state_providers.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('APP SETTINGS')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSettingsTile(context, Icons.person_outline, 'Profile Management', '/profile-management'),
          _buildSettingsTile(context, Icons.lock_outline, 'Security & Biometrics', '/security-settings'),
          _buildSettingsTile(context, Icons.notifications_none_outlined, 'Notification Preferences', '/notification-preferences'),
          _buildSettingsTile(context, Icons.card_membership, 'Subscription Plans', '/subscription-plans'),
          _buildSettingsTile(context, Icons.group_add_outlined, 'Referral Program', '/referral-program'),
          _buildSettingsTile(context, Icons.help_outline, 'Help Center & Support', '/help-center'),
          _buildSettingsTile(context, Icons.policy_outlined, 'Privacy Policy & Terms', '/privacy-policy'),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1)),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            child: const Text('Log Out Account', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String label, String route) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.darkAccent),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(route),
      ),
    );
  }
}

class ProfileManagementScreen extends ConsumerWidget {
  const ProfileManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final nameCtrl = TextEditingController(text: auth.name);

    return Scaffold(
      appBar: AppBar(title: const Text('PROFILE DETAILS')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Display Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Risk Preference'),
                trailing: Text(auth.riskTolerance, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                title: const Text('Subscription Level'),
                trailing: Text(auth.subscriptionLevel, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  ref.read(authProvider.notifier).setupProfile(nameCtrl.text, auth.riskTolerance, auth.subscriptionLevel);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile details updated!')),
                  );
                  context.pop();
                },
                child: const Text('Save Profile Updates'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool bioEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SECURITY OPTIONS')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Enable Biometric Authentication'),
            subtitle: const Text('Use Face ID / Touch ID to secure logins'),
            value: bioEnabled,
            onChanged: (val) {
              setState(() => bioEnabled = val);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Change Account security PIN'),
            subtitle: const Text('Update transaction and access security PIN'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          )
        ],
      ),
    );
  }
}

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool triggerNotifs = true;
  bool generalNotifs = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NOTIFICATIONS')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Strategy Trigger Alerts'),
            subtitle: const Text('Receive push alerts instantly when rules execute'),
            value: triggerNotifs,
            onChanged: (val) {
              setState(() => triggerNotifs = val);
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('General news & reviews'),
            subtitle: const Text('Receive periodic market sentiment reviews'),
            value: generalNotifs,
            onChanged: (val) {
              setState(() => generalNotifs = val);
            },
          )
        ],
      ),
    );
  }
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HELP CENTER')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ExpansionTile(
              title: Text('How does the Rule Builder work?'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('You define indicator parameters (like RSI < 30). Our backend constantly checks real-time WebSocket feeds against these bounds and despatches visual signals immediately.'),
                )
              ],
            ),
          ),
          Card(
            child: ExpansionTile(
              title: Text('Does TradeMentor execute direct transactions?'),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No, TradeMentor is a rule-based advisory tool that provides alerts and analytics. It is paper trading only and does not interface with exchange brokers.'),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MEMBERSHIP PLANS')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildPlanCard('FREE COACH', '\$0', '1 Watchlist • 2 Rule triggers • Standard AI Chat'),
          const SizedBox(height: 12),
          _buildPlanCard('PRO ADVISOR', '\$15/mo', '3 Watchlists • 10 Rule triggers • High Priority AI • Backtesting access'),
          const SizedBox(height: 12),
          _buildPlanCard('ELITE SIGNALS', '\$39/mo', 'Unlimited Watchlists & Rules • Dedicated API feeds • Full Admin Access'),
        ],
      ),
    );
  }

  Widget _buildPlanCard(String name, String cost, String details) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(cost, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.darkAccent)),
            ],
          ),
          const SizedBox(height: 8),
          Text(details, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}

class ReferralProgramScreen extends StatelessWidget {
  const ReferralProgramScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('REFER & EARN')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GlassContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Share TradeMentor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Invite your friends to use TradeMentor and earn free months of Pro membership features.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: AppTheme.darkAccent), borderRadius: BorderRadius.circular(8)),
                child: const Text('MENTORPRO50', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PRIVACY TERMS')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Text('TradeMentor enforces complete data security protocols. User watchlists, portfolio balances, custom strategy rules, and chats logs are strictly confidential and cached locally or synced with secure database rules.', style: TextStyle(fontSize: 14, height: 1.5)),
      ),
    );
  }
}
