import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/state_providers.dart';
import '../widgets/glass_container.dart';

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final inputCtrl = TextEditingController();
  final scrollCtrl = ScrollController();

  @override
  Widget build(BuildContext context) {
    final chatMessages = ref.watch(chatHistoryProvider);
    final portfolio = ref.watch(portfolioProvider);

    double invested = portfolio.fold(0, (sum, item) => sum + item.investedAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TRADEMENTOR AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu),
            onPressed: () => context.push('/chat-history'),
          )
        ],
      ),
      body: Column(
        children: [
          // Prompt suggestions
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildPromptChip('Explain RSI Strategy'),
                const SizedBox(width: 8),
                _buildPromptChip('Evaluate portfolio risk'),
                const SizedBox(width: 8),
                _buildPromptChip('Compare AAPL vs TSLA'),
              ],
            ),
          ),

          // Messages area
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(16.0),
              itemCount: chatMessages.length,
              itemBuilder: (context, idx) {
                final msg = chatMessages[idx];
                final isUser = msg.sender == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.darkAccent.withOpacity(0.2) : Colors.grey.withOpacity(0.08),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(isUser ? 12 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 12),
                      ),
                      border: Border.all(
                        color: isUser ? AppTheme.darkAccent.withOpacity(0.4) : Colors.white.withOpacity(0.05),
                      )
                    ),
                    child: Text(msg.content, style: const TextStyle(fontSize: 14, height: 1.4)),
                  ),
                );
              },
            ),
          ),

          // Text bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: inputCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ask TradeMentor AI...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.darkAccent),
                  onPressed: () {
                    if (inputCtrl.text.isNotEmpty) {
                      final txt = inputCtrl.text;
                      inputCtrl.clear();
                      ref.read(chatHistoryProvider.notifier).sendMessage(
                            txt,
                            HoldingSummary(totalInvested: invested, holdingsCount: portfolio.length),
                          );
                      Future.delayed(const Duration(milliseconds: 300), () {
                        scrollCtrl.animateTo(scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                      });
                    }
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPromptChip(String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      onPressed: () {
        inputCtrl.text = text;
      },
    );
  }
}

class ChatHistoryScreen extends ConsumerWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('PAST CHAT SESSIONS')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Card(
            child: ListTile(
              title: Text('Indicators Analysis'),
              subtitle: Text('RSI crossovers discussion'),
              trailing: Icon(Icons.chevron_right),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('Risk Assessment'),
              subtitle: Text('Portfolio diversification logs'),
              trailing: Icon(Icons.chevron_right),
            ),
          )
        ],
      ),
    );
  }
}

class TradingEducationHubScreen extends StatelessWidget {
  const TradingEducationHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = [
      {'id': '1', 'title': 'Basics of Technical Oscillators', 'desc': 'Learn what momentum oscillators are and how RSI calculates oversold parameters.'},
      {'id': '2', 'title': 'MACD Crossovers & Triggers', 'desc': 'Master MACD histogram lines, crossovers, and setting trigger thresholds.'},
      {'id': '3', 'title': 'Risk Assessment & Allocation', 'desc': 'How to protect capital using Stop Loss rules and sector limits.'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('TRADING ACADEMY')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: modules.length,
        separatorBuilder: (c, i) => const SizedBox(height: 12),
        itemBuilder: (context, idx) {
          final m = modules[idx];
          return Card(
            child: ListTile(
              title: Text(m['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(m['desc'] as String),
              trailing: const Icon(Icons.school, color: AppTheme.darkAccent),
              onTap: () => context.push('/education-detail/${m['id']}'),
            ),
          );
        },
      ),
    );
  }
}

class EducationModuleDetailScreen extends StatelessWidget {
  final String moduleId;

  const EducationModuleDetailScreen({super.key, required this.moduleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LESSON READING')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('MODULE DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              const Text('In this lesson, you will learn the core foundations of rule-based mathematical trading triggers. Indicator values like RSI can highlight technical trends immediately without requiring continuous manual visual checks. TradeMentor monitors these technical updates in real-time, sending advice flags instantly.', style: TextStyle(fontSize: 14, height: 1.5)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Mark Complete & Return'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class RiskEvaluatorScreen extends StatefulWidget {
  const RiskEvaluatorScreen({super.key});

  @override
  State<RiskEvaluatorScreen> createState() => _RiskEvaluatorScreenState();
}

class _RiskEvaluatorScreenState extends State<RiskEvaluatorScreen> {
  double currentRiskLevel = 2.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RISK ASSESSOR')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Assess Your Risk Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Slider(
                value: currentRiskLevel,
                min: 1.0,
                max: 3.0,
                divisions: 2,
                label: currentRiskLevel.toInt() == 1
                    ? 'Conservative'
                    : currentRiskLevel.toInt() == 2
                        ? 'Moderate'
                        : 'Aggressive',
                onChanged: (val) {
                  setState(() => currentRiskLevel = val);
                },
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Conservative', style: TextStyle(fontSize: 11)),
                  Text('Moderate', style: TextStyle(fontSize: 11)),
                  Text('Aggressive', style: TextStyle(fontSize: 11)),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Risk parameters updated in profile successfully!')),
                  );
                  context.pop();
                },
                child: const Text('Save Risk Level'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class StockComparisonScreen extends StatelessWidget {
  const StockComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('STOCK COMPARER')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Apple (AAPL) vs Tesla (TSLA)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Table(
                border: TableBorder.all(color: Colors.grey.withOpacity(0.2)),
                children: const [
                  TableRow(children: [TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold)))), TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('AAPL', style: TextStyle(fontWeight: FontWeight.bold)))), TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('TSLA', style: TextStyle(fontWeight: FontWeight.bold))))]),
                  TableRow(children: [TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Price'))), TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('\$180.50'))), TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('\$175.20')))]),
                  TableRow(children: [TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('RSI (14)'))), TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('45.0'))), TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('35.0')))]),
                  TableRow(children: [TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Beta'))), TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('1.20'))), TableCell(child: Padding(padding: EdgeInsets.all(8.0), child: Text('2.10')))]),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Done'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
