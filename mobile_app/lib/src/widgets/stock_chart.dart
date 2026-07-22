import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_theme.dart';

enum ChartType { line, candlestick }

class StockChartWidget extends StatelessWidget {
  final List<double> prices;
  final String ticker;
  final ChartType chartType;
  final bool isBullish;

  const StockChartWidget({
    super.key,
    required this.prices,
    required this.ticker,
    this.chartType = ChartType.line,
    this.isBullish = true,
  });

  @override
  Widget build(BuildContext context) {
    if (prices.isEmpty) {
      return const Center(child: Text('No historical pricing data available.'));
    }

    final accentColor = isBullish ? AppTheme.bullColor : AppTheme.bearColor;

    if (chartType == ChartType.candlestick) {
      // Mocking candlesticks using FL Bar Chart
      return BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: _generateCandlestickGroups(accentColor),
        ),
      );
    }

    // Default line chart rendering
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: prices.reduce((a, b) => a < b ? a : b) * 0.99,
        maxY: prices.reduce((a, b) => a > b ? a : b) * 1.01,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.black.withOpacity(0.8),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '\$${spot.y.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(prices.length, (i) => FlSpot(i.toDouble(), prices[i])),
            isCurved: true,
            color: accentColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accentColor.withOpacity(0.20),
                  accentColor.withOpacity(0.00),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Generate mock candlesticks using custom bars
  List<BarChartGroupData> _generateCandlestickGroups(Color color) {
    // We create artificial open, high, low, close from stock price array
    return List.generate(prices.length, (index) {
      final basePrice = prices[index];
      final high = basePrice * (1.002 + (index % 3) * 0.001);
      final low = basePrice * (0.998 - (index % 2) * 0.001);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: high,
            fromY: low,
            color: color.withOpacity(0.4),
            width: 2,
          ),
          BarChartRodData(
            toY: basePrice * 1.001,
            fromY: basePrice * 0.999,
            color: color,
            width: 8,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      );
    });
  }
}
