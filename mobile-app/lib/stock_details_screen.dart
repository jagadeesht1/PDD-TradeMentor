import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'main.dart';

// ─── Zone C: Stock Details & Deep-Dive (10 Views) ───

class StockDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> stock;
  final MarketProvider provider;
  const StockDetailsScreen({super.key, required this.stock, required this.provider});

  @override
  State<StockDetailsScreen> createState() => _StockDetailsScreenState();
}

class _StockDetailsScreenState extends State<StockDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _quantityController;
  late TextEditingController _targetPriceController;
  String _tradeType = 'BUY';
  String _selectedCriteria = 'GREATER_THAN';
  bool _submitting = false;
  Map<String, dynamic>? _sentimentData;
  bool _loadingSentiment = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _quantityController = TextEditingController(text: '1');
    _targetPriceController = TextEditingController(
      text: (widget.stock['currentPrice'] as num).toDouble().toStringAsFixed(2),
    );
    _loadSentiment();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quantityController.dispose();
    _targetPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadSentiment() async {
    setState(() => _loadingSentiment = true);
    final data = await widget.provider.fetchSentiment(widget.stock['symbol']);
    if (mounted) {
      setState(() {
        _sentimentData = data;
        _loadingSentiment = false;
      });
    }
  }

  int _getHeldQuantity() {
    if (widget.provider.portfolio == null || widget.provider.portfolio!['holdings'] == null) {
      return 0;
    }
    final holdings = widget.provider.portfolio!['holdings'] as List;
    for (var h in holdings) {
      if (h['symbol'] == widget.stock['symbol']) {
        return h['quantity'] as int;
      }
    }
    return 0;
  }

  void _submitTrade() async {
    final int? qty = int.tryParse(_quantityController.text.trim());
    if (qty == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity (>= 1)'), backgroundColor: AppColors.lossRed),
      );
      return;
    }

    final price = (widget.stock['currentPrice'] as num).toDouble();
    final totalValue = qty * price;

    if (_tradeType == 'BUY' && totalValue > widget.provider.walletBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient balance. Need ₹${totalValue.toStringAsFixed(2)}, have ₹${widget.provider.walletBalance.toStringAsFixed(2)}'),
          backgroundColor: AppColors.lossRed,
        ),
      );
      return;
    }

    if (_tradeType == 'SELL') {
      final heldQty = _getHeldQuantity();
      if (qty > heldQty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot sell $qty shares. You only hold $heldQty.'),
            backgroundColor: AppColors.lossRed,
          ),
        );
        return;
      }
    }

    setState(() => _submitting = true);
    final result = await widget.provider.executeTrade(
      widget.stock['symbol'],
      _tradeType,
      qty,
    );
    setState(() => _submitting = false);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: AppColors.gainGreen),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']), backgroundColor: AppColors.lossRed),
        );
      }
    }
  }

  void _submitAlert() async {
    final double? target = double.tryParse(_targetPriceController.text.trim());
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Target Price format'), backgroundColor: AppColors.lossRed),
      );
      return;
    }

    setState(() => _submitting = true);
    final success = await widget.provider.createAlert(
      widget.stock['symbol'],
      target,
      _selectedCriteria,
    );
    setState(() => _submitting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Alert rule active for ${widget.stock['symbol']} at ₹${target.toStringAsFixed(2)}'), backgroundColor: AppColors.gainGreen),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to deploy alert rule'), backgroundColor: AppColors.lossRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final symbol = widget.stock['symbol'];
    final name = widget.stock['name'];
    final price = (widget.stock['currentPrice'] as num).toDouble();
    final pChange = (widget.stock['pChange'] as num).toDouble();
    final isGainer = pChange >= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(symbol, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(name, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              widget.provider.fetchMarketData();
              _loadSentiment();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gainGreen,
          labelColor: AppColors.gainGreen,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'CHART & MACD'),
            Tab(text: 'METRICS'),
            Tab(text: 'SENTIMENT'),
            Tab(text: 'ORDER'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChartAndIndicatorsTab(price, isGainer),
          _buildMetricsTab(symbol, price),
          _buildSentimentTab(symbol),
          _buildOrderTicketTab(price),
        ],
      ),
    );
  }

  // ─── Sub-View 1 & 2: Chart & Technical Indicators ───
  Widget _buildChartAndIndicatorsTab(double currentPrice, bool isGainer) {
    final history = widget.provider.priceHistory[widget.stock['symbol']] ?? [];
    
    // Derived numerical Technical Indicators
    final double sma20 = currentPrice * 0.992;
    final double sma50 = currentPrice * 0.975;
    final double rsi = 45.0 + (currentPrice.hashCode % 20); // Simulated 45-65 RSI
    final String rsiSignal = rsi > 70 ? 'Overbought (Sell)' : rsi < 30 ? 'Oversold (Buy)' : 'Neutral (Hold)';
    final String macdCross = (currentPrice.hashCode % 2 == 0) ? 'Bullish MACD Crossover' : 'Bearish MACD Divergence';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₹${currentPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            Row(
              children: [
                Icon(isGainer ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: isGainer ? AppColors.gainGreen : AppColors.lossRed, size: 24),
                Text(
                  '${isGainer ? "+" : ""}${(widget.stock['pChange'] as num).toDouble().toStringAsFixed(2)}%',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isGainer ? AppColors.gainGreen : AppColors.lossRed),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          padding: const EdgeInsets.only(top: 10, right: 10, bottom: 5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: history.length < 2
              ? const Center(child: Text('Simulating tick stream...', style: TextStyle(color: AppColors.textMuted)))
              : LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.03), strokeWidth: 1),
                    ),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          history.length,
                          (index) => FlSpot(index.toDouble(), history[index]),
                        ),
                        isCurved: true,
                        color: isGainer ? AppColors.gainGreen : AppColors.lossRed,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: (isGainer ? AppColors.gainGreen : AppColors.lossRed).withOpacity(0.1),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 24),
        const Text('Technical Indicator Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildIndicatorRow('Relative Strength Index (RSI 14)', rsi.toStringAsFixed(1), rsiSignal, rsi > 70 ? AppColors.lossRed : rsi < 30 ? AppColors.gainGreen : Colors.orange),
        _buildIndicatorRow('Simple Moving Average (20-day SMA)', '₹${sma20.toStringAsFixed(2)}', currentPrice >= sma20 ? 'Above (Bullish)' : 'Below (Bearish)', currentPrice >= sma20 ? AppColors.gainGreen : AppColors.lossRed),
        _buildIndicatorRow('Simple Moving Average (50-day SMA)', '₹${sma50.toStringAsFixed(2)}', currentPrice >= sma50 ? 'Above (Bullish)' : 'Below (Bearish)', currentPrice >= sma50 ? AppColors.gainGreen : AppColors.lossRed),
        _buildIndicatorRow('MACD Signal Alignment', '12, 26, 9', macdCross, macdCross.contains('Bullish') ? AppColors.gainGreen : AppColors.lossRed),
      ],
    );
  }

  Widget _buildIndicatorRow(String title, String val, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── Sub-View 3, 4, 5, 6, 7: Fundamentals, Financials, Shareholding, Peers, Corporate Actions ───
  Widget _buildMetricsTab(String symbol, double price) {
    // Derived static data structures based on symbol hash codes to simulate actual stocks
    final int hash = symbol.hashCode;
    final double peRatio = 12.0 + (hash % 30);
    final double eps = price / peRatio;
    final double divYield = 0.5 + (hash % 4) * 0.75;
    final double beta = 0.7 + (hash % 8) * 0.12;
    final String marketCap = '${(price * 12.5).toStringAsFixed(0)} Cr';
    final double high52 = price * 1.22;
    final double low52 = price * 0.76;

    // Financials
    final List<Map<String, String>> quarters = [
      {'q': 'Q1 Simulated', 'rev': '₹${(price * 4.5).toStringAsFixed(0)} Cr', 'profit': '₹${(price * 0.6).toStringAsFixed(0)} Cr'},
      {'q': 'Q2 Simulated', 'rev': '₹${(price * 4.8).toStringAsFixed(0)} Cr', 'profit': '₹${(price * 0.7).toStringAsFixed(0)} Cr'},
      {'q': 'Q3 Simulated', 'rev': '₹${(price * 5.2).toStringAsFixed(0)} Cr', 'profit': '₹${(price * 0.8).toStringAsFixed(0)} Cr'},
    ];

    // Shareholding
    final double promoter = 40.0 + (hash % 25);
    final double fii = 15.0 + (hash % 12);
    final double dii = 10.0 + (hash % 10);
    final double public = 100.0 - promoter - fii - dii;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Fundamentals
        const Text('Fundamentals', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.8,
            children: [
              _buildGridItem('P/E Ratio', peRatio.toStringAsFixed(2)),
              _buildGridItem('EPS (Earnings/Sh)', '₹${eps.toStringAsFixed(2)}'),
              _buildGridItem('Div Yield (%)', '${divYield.toStringAsFixed(2)}%'),
              _buildGridItem('Beta volatility', beta.toStringAsFixed(2)),
              _buildGridItem('Market Capitalization', marketCap),
              _buildGridItem('52-Week Range', '₹${low52.toStringAsFixed(0)} - ₹${high52.toStringAsFixed(0)}'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Financial Statements
        const Text('Quarterly Financial Statements', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Table(
            children: [
              const TableRow(
                children: [
                  Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Quarter', style: TextStyle(fontSize: 10, color: AppColors.textSecondary))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Revenue', style: TextStyle(fontSize: 10, color: AppColors.textSecondary))),
                  Padding(padding: EdgeInsets.symmetric(vertical: 4), child: Text('Net Profit', style: TextStyle(fontSize: 10, color: AppColors.textSecondary))),
                ],
              ),
              ...quarters.map((q) => TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(q['q']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(q['rev']!, style: const TextStyle(fontSize: 12))),
                      Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(q['profit']!, style: const TextStyle(fontSize: 12, color: AppColors.gainGreen))),
                    ],
                  )),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Shareholding Pattern
        const Text('Shareholding Distribution Pattern', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(flex: promoter.round(), child: Container(height: 12, color: const Color(0xFF2196F3))),
                  Expanded(flex: fii.round(), child: Container(height: 12, color: const Color(0xFF9C27B0))),
                  Expanded(flex: dii.round(), child: Container(height: 12, color: const Color(0xFF4CAF50))),
                  Expanded(flex: public.round(), child: Container(height: 12, color: const Color(0xFFFFC107))),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPatternIndicator('Promoter', '${promoter.toStringAsFixed(1)}%', const Color(0xFF2196F3)),
                  _buildPatternIndicator('FII', '${fii.toStringAsFixed(1)}%', const Color(0xFF9C27B0)),
                  _buildPatternIndicator('DII', '${dii.toStringAsFixed(1)}%', const Color(0xFF4CAF50)),
                  _buildPatternIndicator('Public', '${public.toStringAsFixed(1)}%', const Color(0xFFFFC107)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Peer Comparison
        const Text('Sectoral Peer Comparison', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildPeerRow('Metric', symbol, 'Sector Avg'),
              const Divider(color: Colors.white12),
              _buildPeerRow('P/E Ratio', peRatio.toStringAsFixed(1), (peRatio * 0.94).toStringAsFixed(1)),
              _buildPeerRow('Div Yield', '${divYield.toStringAsFixed(1)}%', '${(divYield * 1.1).toStringAsFixed(1)}%'),
              _buildPeerRow('Volatility Beta', beta.toStringAsFixed(2), '1.05'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Corporate Actions
        const Text('Corporate Actions History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _buildActionRow('Final Dividend Declared', '₹5.50 / share', '08-Jan-2026'),
              const Divider(color: Colors.white10, height: 12),
              _buildActionRow('Stock Split simulated', 'Ratio 1:2', '14-Sep-2025'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPatternIndicator(String name, String pct, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(name, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 2),
        Text(pct, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPeerRow(String label, String val1, String val2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))),
          Expanded(child: Text(val1, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          Expanded(child: Text(val2, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        ],
      ),
    );
  }

  Widget _buildActionRow(String action, String detail, String date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(action, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(detail, style: const TextStyle(fontSize: 11, color: AppColors.gainGreen)),
          ],
        ),
        Text(date, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }

  // ─── Sub-View 8: AI News Sentiment & Headlines ───
  Widget _buildSentimentTab(String symbol) {
    if (_loadingSentiment) {
      return const Center(child: CircularProgressIndicator(color: AppColors.gainGreen));
    }

    final double score = _sentimentData != null ? (_sentimentData!['score'] as num).toDouble() : 0.0;
    final String label = _sentimentData != null ? _sentimentData!['label'] : 'NEUTRAL';
    final String summary = _sentimentData != null ? _sentimentData!['summary'] : 'No news found.';

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
                  Icon(Icons.psychology, color: AppColors.gainGreen, size: 20),
                  SizedBox(width: 8),
                  Text('AI Sentiment Meter Audit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Score: $score', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (label == 'BULLISH' ? AppColors.gainGreen : label == 'BEARISH' ? AppColors.lossRed : Colors.orangeAccent).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: label == 'BULLISH' ? AppColors.gainGreen : label == 'BEARISH' ? AppColors.lossRed : Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Simulated slider meter
              Stack(
                children: [
                  Container(height: 8, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
                  Positioned(
                    left: ((score + 1.0) / 2.0) * MediaQuery.of(context).size.width * 0.74,
                    top: 0,
                    child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.gainGreen, shape: BoxShape.circle)),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text('Sentiment Advisory Synthesis:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(summary, style: const TextStyle(fontSize: 12, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Recent Market Sentiment Headlines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildNewsHeadline('Quarterly margins projected to hit record high on low operations cost.', 'BULLISH', AppColors.gainGreen),
        _buildNewsHeadline('FII net capital volumes show short-term rebalancing outflow triggers.', 'BEARISH', AppColors.lossRed),
        _buildNewsHeadline('Technical breakouts consolidated near today\'s opening margins.', 'NEUTRAL', Colors.orangeAccent),
      ],
    );
  }

  Widget _buildNewsHeadline(String headline, String badge, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.02)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(headline, style: const TextStyle(fontSize: 12, height: 1.3)),
                const SizedBox(height: 6),
                const Text('MarketNews wire · 2 hours ago', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
            child: Text(badge, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  // ─── Sub-View 9 & 10: Order Ticket & Price Alert Setup ───
  Widget _buildOrderTicketTab(double price) {
    final double inputQty = double.tryParse(_quantityController.text) ?? 0.0;
    final double estimatedCost = inputQty * price;
    final int heldQty = _getHeldQuantity();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tradeType = 'BUY'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _tradeType == 'BUY' ? AppColors.gainGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'BUY SHARES',
                        style: TextStyle(
                          color: _tradeType == 'BUY' ? Colors.black : AppColors.gainGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tradeType = 'SELL'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _tradeType == 'SELL' ? AppColors.lossRed : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'SELL HOLDINGS',
                        style: TextStyle(
                          color: _tradeType == 'SELL' ? Colors.white : AppColors.lossRed,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Equity Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('ESTIMATED COST', style: TextStyle(fontSize: 8, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      '₹${estimatedCost.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _tradeType == 'BUY' ? AppColors.gainGreen : AppColors.lossRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Balance: ₹${widget.provider.walletBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text('Held Position: $heldQty shares', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submitTrade,
            style: ElevatedButton.styleFrom(
              backgroundColor: _tradeType == 'BUY' ? AppColors.gainGreen : AppColors.lossRed,
              foregroundColor: _tradeType == 'BUY' ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _submitting
                ? const CircularProgressIndicator(color: Colors.black)
                : Text('CONFIRM $_tradeType ORDER', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(color: Colors.white12),
        const SizedBox(height: 16),
        const Text('Establish Conditional Alert Trigger', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _selectedCriteria,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                ),
                dropdownColor: AppColors.surface,
                items: const [
                  DropdownMenuItem(value: 'GREATER_THAN', child: Text('Price >=', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'LESS_THAN', child: Text('Price <=', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'STOP_LOSS', child: Text('Stop Loss <=', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCriteria = val);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: TextField(
                controller: _targetPriceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target Price (₹)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 44,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submitAlert,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gainGreen.withOpacity(0.15),
              foregroundColor: AppColors.gainGreen,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppColors.gainGreen, width: 0.5)),
            ),
            child: _submitting
                ? const CircularProgressIndicator(color: AppColors.gainGreen)
                : const Text('DEPLOY ALERT RULE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
