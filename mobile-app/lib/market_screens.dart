import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'stock_details_screen.dart';

// ─── Zone B: Market Discovery & Analytics (12 Views) ───

class MarketScannersTab extends StatefulWidget {
  final MarketProvider provider;
  const MarketScannersTab({super.key, required this.provider});

  @override
  State<MarketScannersTab> createState() => _MarketScannersTabState();
}

class _MarketScannersTabState extends State<MarketScannersTab> {
  String _activeScanner = 'GAINERS'; // 'GAINERS', 'LOSERS', 'VOLUME', 'HIGH52W', 'LOW52W'

  List<dynamic> _getScannedStocks() {
    final stocks = List<dynamic>.from(widget.provider.stocks);
    if (stocks.isEmpty) return [];

    switch (_activeScanner) {
      case 'GAINERS':
        stocks.sort((a, b) => (b['pChange'] as num).compareTo(a['pChange'] as num));
        return stocks.take(5).toList();
      case 'LOSERS':
        stocks.sort((a, b) => (a['pChange'] as num).compareTo(b['pChange'] as num));
        return stocks.take(5).toList();
      case 'VOLUME':
        // Simulated: Sort by price to mock volume correlation
        stocks.sort((a, b) => (b['currentPrice'] as num).compareTo(a['currentPrice'] as num));
        return stocks.take(5).toList();
      case 'HIGH52W':
        // Simulated: Stocks with daily gain > 0.5% close to high
        return stocks.where((s) => (s['pChange'] as num) > 0.5).toList();
      case 'LOW52W':
        // Simulated: Stocks with daily loss < -0.5% close to low
        return stocks.where((s) => (s['pChange'] as num) < -0.5).toList();
      default:
        return stocks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannedList = _getScannedStocks();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildScannerChip('Gainers', 'GAINERS'),
              _buildScannerChip('Losers', 'LOSERS'),
              _buildScannerChip('Volume Shockers', 'VOLUME'),
              _buildScannerChip('52-W High', 'HIGH52W'),
              _buildScannerChip('52-W Low', 'LOW52W'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.flash_on, color: AppColors.gainGreen, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Technical Scan Results ($_activeScanner)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (scannedList.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text('No breakout stocks matching this tick scanner.', style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: scannedList.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.04)),
                  itemBuilder: (context, index) {
                    final stock = scannedList[index];
                    final pChange = (stock['pChange'] as num).toDouble();
                    final isPositive = pChange >= 0;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StockDetailsScreen(stock: stock, provider: widget.provider),
                          ),
                        );
                      },
                      title: Text(stock['symbol'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(stock['name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('₹${(stock['currentPrice'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            '${isPositive ? "+" : ""}${pChange.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPositive ? AppColors.gainGreen : AppColors.lossRed,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScannerChip(String label, String key) {
    final active = _activeScanner == key;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: active,
        onSelected: (val) {
          if (val) {
            setState(() {
              _activeScanner = key;
            });
          }
        },
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.gainGreen.withOpacity(0.15),
        labelStyle: TextStyle(
          color: active ? AppColors.gainGreen : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        side: BorderSide(
          color: active ? AppColors.gainGreen : Colors.white.withOpacity(0.05),
        ),
      ),
    );
  }
}

class MarketSectorsTab extends StatelessWidget {
  final MarketProvider provider;
  const MarketSectorsTab({super.key, required this.provider});

  static const List<Map<String, dynamic>> sectorsList = [
    { 'name': 'IT', 'code': 'IT', 'color': Color(0xFF9C27B0), 'desc': 'Nifty IT constituents representing software development.' },
    { 'name': 'Financial Services', 'code': 'FIN', 'color': Color(0xFF4CAF50), 'desc': 'Banking, lending, and simulated fintech core.' },
    { 'name': 'Energy', 'code': 'ENE', 'color': Color(0xFF2196F3), 'desc': 'Oil, power grids, gas, and green utilities.' },
    { 'name': 'Telecom', 'code': 'TEL', 'color': Color(0xFFFFC107), 'desc': 'Data carriers, communications, and tower networks.' },
    { 'name': 'Construction', 'code': 'CON', 'color': Color(0xFFFF5722), 'desc': 'Infrastructure development and heavy engineering.' },
    { 'name': 'FMCG', 'code': 'FMCG', 'color': Color(0xFFE91E63), 'desc': 'Fast moving consumer goods & staples giants.' },
    { 'name': 'Automobile', 'code': 'AUTO', 'color': Color(0xFFF44336), 'desc': 'Automotive manufacturers and parts suppliers.' }
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: sectorsList.length,
      itemBuilder: (context, index) {
        final sec = sectorsList[index];
        final constituents = provider.stocks.where((s) => s['sector'] == sec['name']).toList();
        final double avgPrice = constituents.isEmpty
            ? 0.0
            : constituents.fold<double>(0.0, (acc, cur) => acc + (cur['currentPrice'] as num).toDouble()) / constituents.length;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SectorDetailsScreen(
                  sectorName: sec['name'],
                  sectorCode: sec['code'],
                  description: sec['desc'],
                  color: sec['color'],
                  provider: provider,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        sec['name'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: sec['color'].withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: sec['color'].withOpacity(0.3), width: 0.5),
                      ),
                      child: Text(
                        sec['code'],
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: sec['color']),
                      ),
                    )
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${constituents.length} Equities',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Avg Price: ₹${avgPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gainGreen),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SectorDetailsScreen extends StatelessWidget {
  final String sectorName;
  final String sectorCode;
  final String description;
  final Color color;
  final MarketProvider provider;

  const SectorDetailsScreen({
    super.key,
    required this.sectorName,
    required this.sectorCode,
    required this.description,
    required this.color,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final constituents = provider.stocks.where((s) => s['sector'] == sectorName).toList();
    final double avgPrice = constituents.isEmpty
        ? 0.0
        : constituents.fold<double>(0.0, (acc, cur) => acc + (cur['currentPrice'] as num).toDouble()) / constituents.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('$sectorName Sector', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.surface, AppColors.surface.withOpacity(0.5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$sectorName Index constituents',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        sectorCode,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: color),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Weighted Sector Avg Price', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text('₹${avgPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.gainGreen)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Equity Constituents List',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (constituents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: Text('No stocks registered in this sector.', style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: constituents.length,
              separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.04)),
              itemBuilder: (context, index) {
                final stock = constituents[index];
                final pChange = (stock['pChange'] as num).toDouble();
                final isPositive = pChange >= 0;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StockDetailsScreen(stock: stock, provider: provider),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.gainGreen,
                    child: Text(stock['symbol'].substring(0, 2)),
                  ),
                  title: Text(stock['symbol'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(stock['name'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('₹${(stock['currentPrice'] as num).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: isPositive ? AppColors.gainGreen : AppColors.lossRed, size: 16),
                          Text(
                            '${isPositive ? "+" : ""}${pChange.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPositive ? AppColors.gainGreen : AppColors.lossRed,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
