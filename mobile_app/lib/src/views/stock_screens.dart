import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../providers/state_providers.dart';
import '../widgets/glass_container.dart';
import '../widgets/stock_chart.dart';

class StockDetailsScreen extends ConsumerWidget {
  final String ticker;

  const StockDetailsScreen({super.key, required this.ticker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocksAsync = ref.watch(stocksListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(ticker)),
      body: stocksAsync.when(
        data: (stocks) {
          final stock = stocks.firstWhere(
            (s) => s.ticker == ticker.toUpperCase(),
            orElse: () => throw Exception('Stock not found'),
          );
          final isBull = stock.change >= 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stock.companyName, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('\$${stock.price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isBull ? AppTheme.bullColor : AppTheme.bearColor).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${isBull ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(color: isBull ? AppTheme.bullColor : AppTheme.bearColor, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // Chart Container
                GlassContainer(
                  height: 250,
                  child: StockChartWidget(
                    prices: stock.history,
                    ticker: stock.ticker,
                    chartType: ChartType.line,
                    isBullish: isBull,
                  ),
                ),
                const SizedBox(height: 16),

                // Navigation buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.analytics_outlined),
                        label: const Text('Technical Analysis'),
                        onPressed: () => context.push('/technical-analysis/$ticker'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.pie_chart_outline),
                        label: const Text('Fundamentals'),
                        onPressed: () => context.push('/fundamental-analysis/$ticker'),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // Key metrics card
                const Text('KEY STATISTICS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                GlassContainer(
                  child: Table(
                    children: [
                      _buildTableRow('Volume', stock.volume.toString()),
                      _buildTableRow('RSI (14)', stock.rsi.toStringAsFixed(2)),
                      _buildTableRow('52-Week High', '\$${(stock.price * 1.15).toStringAsFixed(2)}'),
                      _buildTableRow('52-Week Low', '\$${(stock.price * 0.82).toStringAsFixed(2)}'),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Order Ticket launch Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.bullColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => context.push('/order-entry/$ticker?action=buy'),
                        child: const Text('BUY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.bearColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => context.push('/order-entry/$ticker?action=sell'),
                        child: const Text('SELL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                )
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const Center(child: Text('Error locating ticker details.')),
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)),
        )
      ],
    );
  }
}

class TechnicalAnalysisScreen extends ConsumerWidget {
  final String ticker;

  const TechnicalAnalysisScreen({super.key, required this.ticker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocksAsync = ref.watch(stocksListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('$ticker - TECHNICALS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: () => context.push('/chart-fullscreen/$ticker'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/technical-indicators/$ticker'),
          )
        ],
      ),
      body: stocksAsync.when(
        data: (stocks) {
          final s = stocks.firstWhere((element) => element.ticker == ticker.toUpperCase());
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Interactive Candlestick Chart
                const Text('Candlestick Layout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                GlassContainer(
                  height: 260,
                  child: StockChartWidget(
                    prices: s.history,
                    ticker: s.ticker,
                    chartType: ChartType.candlestick,
                    isBullish: s.change >= 0,
                  ),
                ),
                const SizedBox(height: 20),

                // Oscillators overview
                const Text('OSCILLATORS & INDICATORS', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                GlassContainer(
                  child: Column(
                    children: [
                      _buildIndicatorRow('Relative Strength Index (RSI)', s.rsi.toStringAsFixed(2),
                          s.rsi < 30 ? 'Oversold (Buy)' : (s.rsi > 70 ? 'Overbought (Sell)' : 'Neutral')),
                      const Divider(),
                      _buildIndicatorRow('MACD (12, 26)', '-0.45', 'Bearish Crossover'),
                      const Divider(),
                      _buildIndicatorRow('Exponential Moving Average (EMA)', '\$${(s.price * 0.985).toStringAsFixed(2)}', 'Price Above (Bullish)'),
                    ],
                  ),
                )
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const Center(child: Text('Fail loading technical indicator summaries')),
      ),
    );
  }

  Widget _buildIndicatorRow(String name, String value, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(status, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

class FundamentalAnalysisScreen extends StatelessWidget {
  final String ticker;

  const FundamentalAnalysisScreen({super.key, required this.ticker});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$ticker - FUNDAMENTALS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('VALUATION MULTIPLES', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GlassContainer(
              child: Table(
                children: const [
                  TableRow(children: [Padding(padding: EdgeInsets.all(8.0), child: Text('PE Ratio')), Padding(padding: EdgeInsets.all(8.0), child: Text('28.42', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)))]),
                  TableRow(children: [Padding(padding: EdgeInsets.all(8.0), child: Text('Price to Book')), Padding(padding: EdgeInsets.all(8.0), child: Text('7.85', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)))]),
                  TableRow(children: [Padding(padding: EdgeInsets.all(8.0), child: Text('EV / EBITDA')), Padding(padding: EdgeInsets.all(8.0), child: Text('18.20', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)))]),
                  TableRow(children: [Padding(padding: EdgeInsets.all(8.0), child: Text('Dividend Yield')), Padding(padding: EdgeInsets.all(8.0), child: Text('0.85%', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)))]),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('FINANCIAL STATEMENT TREND', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            GlassContainer(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(x: 2023, barRods: [BarChartRodData(toY: 380, color: Colors.blue, width: 16)]),
                    BarChartGroupData(x: 2024, barRods: [BarChartRodData(toY: 395, color: Colors.blue, width: 16)]),
                    BarChartGroupData(x: 2025, barRods: [BarChartRodData(toY: 410, color: Colors.blue, width: 16)]),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ChartFullScreen extends ConsumerWidget {
  final String ticker;

  const ChartFullScreen({super.key, required this.ticker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stocksAsync = ref.watch(stocksListProvider);

    return Scaffold(
      appBar: AppBar(title: Text('$ticker Landscape Chart')),
      body: RotatedBox(
        quarterTurns: 1, // Force Landscape view
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: stocksAsync.when(
            data: (stocks) {
              final s = stocks.firstWhere((element) => element.ticker == ticker.toUpperCase());
              return StockChartWidget(
                prices: s.history,
                ticker: s.ticker,
                isBullish: s.change >= 0,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => const Center(child: Text('Landscape loading failed')),
          ),
        ),
      ),
    );
  }
}

class TechnicalIndicatorsScreen extends StatelessWidget {
  final String ticker;

  const TechnicalIndicatorsScreen({super.key, required this.ticker});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('INDICATOR CONFIGS')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          Text('OSCILLATOR PARAMETERS', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Card(
            child: ListTile(
              title: Text('RSI Period'),
              trailing: SizedBox(width: 80, child: TextField(textAlign: TextAlign.center, decoration: InputDecoration(hintText: '14'))),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('MACD Fast Period'),
              trailing: SizedBox(width: 80, child: TextField(textAlign: TextAlign.center, decoration: InputDecoration(hintText: '12'))),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('MACD Slow Period'),
              trailing: SizedBox(width: 80, child: TextField(textAlign: TextAlign.center, decoration: InputDecoration(hintText: '26'))),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderEntryScreen extends ConsumerWidget {
  final String ticker;

  const OrderEntryScreen({super.key, required this.ticker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qtyController = TextEditingController(text: '10');
    final limitController = TextEditingController(text: '180.00');

    return Scaffold(
      appBar: AppBar(title: Text('PLACE ORDER - $ticker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: GlassContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity of Shares', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: limitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Limit Buy Price (\$)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Estimated Order Cost:', style: TextStyle(color: Colors.grey)),
                  Text('\$1,800.00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final qty = double.tryParse(qtyController.text) ?? 1.0;
                  final price = double.tryParse(limitController.text) ?? 180.0;
                  ref.read(portfolioProvider.notifier).buyStock(ticker, '$ticker Inc', qty, price);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Simulated order executed: bought $qty shares of $ticker')),
                  );
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.bullColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('EXECUTE BUY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
