import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

// ─── Zone F: AI Mentor & Advisory (6 Views) ───

class AIMentorTab extends StatefulWidget {
  final MarketProvider provider;
  const AIMentorTab({super.key, required this.provider});

  @override
  State<AIMentorTab> createState() => _AIMentorTabState();
}

class _AIMentorTabState extends State<AIMentorTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatController = TextEditingController();
  final _scrollController = ScrollController();

  // Stock Comparison Form state
  String? _compareSym1;
  String? _compareSym2;
  Map<String, dynamic>? _comparisonResult;

  // Glossary search state
  String _glossarySearch = '';
  final Map<String, String> _glossaryData = {
    'PE Ratio': 'The Price-to-Earnings (P/E) ratio measures the share price relative to earnings per share. A high P/E could mean a stock is overvalued or has high growth potential; a low P/E suggests undervaluation or slower growth.',
    'Stop Loss': 'A Stop Loss is an automatic trigger order set to sell a security when it reaches a specific price limit, designed to limit investor losses on an adverse market move.',
    'RSI': 'The Relative Strength Index (RSI) is a technical momentum indicator ranging from 0 to 100. Traditionally, an RSI > 70 indicates a stock is overbought, and < 30 indicates oversold.',
    'MACD': 'Moving Average Convergence Divergence (MACD) is a trend-following momentum indicator showing the relationship between two moving averages of a stock\'s price.',
    'Portfolio': 'A portfolio is a grouping of financial assets such as stocks, bonds, and simulated cash. Rebalancing helps maintain your target risk profile.',
    'Unrealized PNL': 'Unrealized P&L represents the gains or losses in your open positions based on current market prices. It becomes a realized gain/loss only after you sell.',
    'Realized PNL': 'Realized P&L is the actual profit or loss locked in after a stock position is closed (sold).',
    'Limit Order': 'A limit order is an order to buy or sell a stock with a restriction on the maximum price to be paid or minimum price to be received.',
    'Market Cap': 'Market Capitalization is the total market value of a company\'s outstanding shares of stock, calculated by multiplying shares outstanding by the current share price.'
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.provider.stocks.length >= 2) {
      _compareSym1 = widget.provider.stocks[0]['symbol'];
      _compareSym2 = widget.provider.stocks[1]['symbol'];
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? presetText]) async {
    final text = presetText ?? _chatController.text.trim();
    if (text.isEmpty) return;
    _chatController.clear();
    _scrollToBottom();
    await widget.provider.sendAiMessage(text);
    _scrollToBottom();
  }

  void _executeCompare() {
    if (_compareSym1 == null || _compareSym2 == null) return;
    final s1 = widget.provider.stocks.firstWhere((s) => s['symbol'] == _compareSym1);
    final s2 = widget.provider.stocks.firstWhere((s) => s['symbol'] == _compareSym2);

    setState(() {
      _comparisonResult = {
        's1': s1,
        's2': s2,
        'pe1': (12.0 + (s1['symbol'].hashCode % 30)).toStringAsFixed(1),
        'pe2': (12.0 + (s2['symbol'].hashCode % 30)).toStringAsFixed(1),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_compareSym1 == null && widget.provider.stocks.length >= 2) {
      _compareSym1 = widget.provider.stocks[0]['symbol'];
      _compareSym2 = widget.provider.stocks[1]['symbol'];
    }

    return Column(
      children: [
        // AI Mentor Header
        Container(
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
                  const Icon(Icons.psychology, color: AppColors.gainGreen, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'TradeMentor AI',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.gainGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Profile: ${widget.provider.riskProfile.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: AppColors.gainGreen),
                ),
              ),
            ],
          ),
        ),

        // Sub Tabs
        TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gainGreen,
          labelColor: AppColors.gainGreen,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'AI CHATBOT'),
            Tab(text: 'REBALANCER'),
            Tab(text: 'COMPARE & DICT'),
          ],
        ),

        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildChatTab(),
              _buildRebalancerTab(),
              _buildCompareAndDictTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Sub-View 1: AI Chatbot Screen ───
  Widget _buildChatTab() {
    final history = widget.provider.aiChatHistory;
    final loading = widget.provider.aiLoading;

    final presetPills = [
      'Scan the Market',
      'Compare RELIANCE and TCS',
      'How to rebalance my portfolio?',
      'What is PE Ratio?'
    ];

    return Column(
      children: [
        // Preset suggestions
        Container(
          height: 40,
          margin: const EdgeInsets.only(top: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: presetPills.length,
            itemBuilder: (context, idx) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ActionChip(
                  label: Text(presetPills[idx], style: const TextStyle(fontSize: 10, color: AppColors.gainGreen)),
                  backgroundColor: AppColors.surface,
                  side: BorderSide(color: AppColors.gainGreen.withOpacity(0.2)),
                  padding: const EdgeInsets.all(0),
                  onPressed: () => _sendMessage(presetPills[idx]),
                ),
              );
            },
          ),
        ),

        // Chat Bubble area
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(12),
            itemCount: history.length,
            itemBuilder: (context, idx) {
              final msg = history[idx];
              final isAi = msg['sender'] == 'ai';

              return Align(
                alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isAi ? AppColors.surface : AppColors.gainGreen.withOpacity(0.12),
                    border: Border.all(color: isAi ? Colors.white.withOpacity(0.04) : AppColors.gainGreen.withOpacity(0.2)),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(12),
                      topRight: const Radius.circular(12),
                      bottomLeft: isAi ? const Radius.circular(0) : const Radius.circular(12),
                      bottomRight: isAi ? const Radius.circular(12) : const Radius.circular(0),
                    ),
                  ),
                  child: Text(
                    msg['text'] ?? '',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isAi ? Colors.white : AppColors.gainGreen,
                      height: 1.4,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        if (loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gainGreen)),
                SizedBox(width: 8),
                Text('TradeMentor AI is auditing...', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),

        // Text input bar
        Container(
          padding: const EdgeInsets.all(8),
          color: AppColors.surface,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Ask TradeMentor AI...',
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.gainGreen),
                onPressed: () => _sendMessage(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Sub-View 2, 3: Technical Scan & Portfolio Rebalancer ───
  Widget _buildRebalancerTab() {
    final profile = widget.provider.riskProfile;

    // Derived rebalancing recommendation percentages
    Map<String, double> targetAlloc = {};
    if (profile == 'high') {
      targetAlloc = {'IT & Auto': 60, 'Energy & Industry': 20, 'FMCG & Telecom': 10, 'Wallet Cash': 10};
    } else if (profile == 'low') {
      targetAlloc = {'FMCG': 50, 'Financials': 25, 'Market Indexes': 15, 'Wallet Cash': 10};
    } else {
      targetAlloc = {'Financials': 30, 'IT': 30, 'Energy & Construction': 20, 'FMCG & Auto': 15, 'Wallet Cash': 5};
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart, color: AppColors.gainGreen, size: 20),
                  SizedBox(width: 8),
                  Text('AI Portfolio Allocator Advice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Based on your risk profile (${profile.toUpperCase()}), the AI suggests rebalancing your virtual assets to match these target weights:',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              ...targetAlloc.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('${e.value.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gainGreen)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text('AI Technical Scans Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bullish Breakouts (High Momentum):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.gainGreen)),
              const SizedBox(height: 4),
              Text(
                widget.provider.stocks.where((s) => (s['pChange'] as num) > 0.8).map<String>((s) => s['symbol'] as String).join(', '),
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 14),
              const Text('Bearish Corrections (Dip Candidates):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.lossRed)),
              const SizedBox(height: 4),
              Text(
                widget.provider.stocks.where((s) => (s['pChange'] as num) < -0.8).map<String>((s) => s['symbol'] as String).join(', '),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Sub-View 4, 5, 6: Compare stocks & Term Dictionary ───
  Widget _buildCompareAndDictTab() {
    // Filter glossary search
    final filteredGlossary = _glossarySearch.isEmpty
        ? _glossaryData.entries.toList()
        : _glossaryData.entries.where((e) => e.key.toLowerCase().contains(_glossarySearch.toLowerCase())).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Comparison Form
        const Text('Compare Equities Audit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _compareSym1,
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(labelText: 'Stock 1', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                      items: widget.provider.stocks.map((s) => DropdownMenuItem<String>(value: s['symbol'], child: Text(s['symbol']))).toList(),
                      onChanged: (val) => setState(() => _compareSym1 = val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _compareSym2,
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(labelText: 'Stock 2', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(8)),
                      items: widget.provider.stocks.map((s) => DropdownMenuItem<String>(value: s['symbol'], child: Text(s['symbol']))).toList(),
                      onChanged: (val) => setState(() => _compareSym2 = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: _executeCompare,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gainGreen, foregroundColor: Colors.black),
                  child: const Text('AUDIT SIDE-BY-SIDE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
              if (_comparisonResult != null) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                _buildCompareRow('Sector', _comparisonResult!['s1']['sector'], _comparisonResult!['s2']['sector']),
                _buildCompareRow('Price', '₹${(_comparisonResult!['s1']['currentPrice'] as num).toDouble().toStringAsFixed(2)}', '₹${(_comparisonResult!['s2']['currentPrice'] as num).toDouble().toStringAsFixed(2)}'),
                _buildCompareRow('P/E Ratio', _comparisonResult!['pe1'], _comparisonResult!['pe2']),
                _buildCompareRow('Today\'s P&L', '${_comparisonResult!['s1']['pChange']}%', '${_comparisonResult!['s2']['sChange'] ?? _comparisonResult!['s2']['pChange']}%'),
              ]
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Glossary Dictionary
        const Text('AI Finance Term Dictionary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          onChanged: (val) => setState(() => _glossarySearch = val),
          decoration: const InputDecoration(
            hintText: 'Search terminology (e.g. RSI, Stop Loss)...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(8),
          ),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredGlossary.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final entry = filteredGlossary[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.03)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.gainGreen)),
                  const SizedBox(height: 6),
                  Text(entry.value, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCompareRow(String metric, String val1, String val2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(child: Text(metric, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          Expanded(child: Text(val1, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(child: Text(val2, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.gainGreen))),
        ],
      ),
    );
  }
}
