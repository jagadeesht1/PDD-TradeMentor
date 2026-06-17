import 'package:flutter/material.dart';
import 'main.dart';

// ─── Zone E: Rule Trigger Manager (5 Views) ───

class RuleWizardView extends StatefulWidget {
  final MarketProvider provider;
  const RuleWizardView({super.key, required this.provider});

  @override
  State<RuleWizardView> createState() => _RuleWizardViewState();
}

class _RuleWizardViewState extends State<RuleWizardView> {
  String _ruleType = 'SMA'; // 'SMA', 'RSI', 'TRAILING'
  String? _selectedSymbol;
  String _smaPeriod = '20'; // '20', '50'
  String _smaDirection = 'ABOVE'; // 'ABOVE', 'BELOW'
  double _rsiThreshold = 30.0; // 30.0 (Oversold), 70.0 (Overbought)
  double _trailPercent = 5.0; // 3%, 5%, 8%

  @override
  void initState() {
    super.initState();
    if (widget.provider.stocks.isNotEmpty) {
      _selectedSymbol = widget.provider.stocks[0]['symbol'];
    }
  }

  void _deployRule() async {
    if (_selectedSymbol == null) return;

    final stock = widget.provider.stocks.firstWhere((s) => s['symbol'] == _selectedSymbol);
    final double price = (stock['currentPrice'] as num).toDouble();
    double targetPrice = price;
    String criteria = 'GREATER_THAN';

    if (_ruleType == 'SMA') {
      if (_smaPeriod == '20') {
        targetPrice = _smaDirection == 'ABOVE' ? price * 1.01 : price * 0.99;
      } else {
        targetPrice = _smaDirection == 'ABOVE' ? price * 1.03 : price * 0.97;
      }
      criteria = _smaDirection == 'ABOVE' ? 'GREATER_THAN' : 'LESS_THAN';
    } else if (_ruleType == 'RSI') {
      targetPrice = _rsiThreshold == 30.0 ? price * 0.95 : price * 1.05;
      criteria = _rsiThreshold == 30.0 ? 'LESS_THAN' : 'GREATER_THAN';
    } else if (_ruleType == 'TRAILING') {
      targetPrice = price * (1.0 - (_trailPercent / 100.0));
      criteria = 'STOP_LOSS';
    }

    final success = await widget.provider.createAlert(
      _selectedSymbol!,
      targetPrice,
      criteria,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rule deployed! Active on $_selectedSymbol at target ₹${targetPrice.toStringAsFixed(2)}'),
            backgroundColor: AppColors.gainGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to deploy rule'), backgroundColor: AppColors.lossRed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedSymbol == null && widget.provider.stocks.isNotEmpty) {
      _selectedSymbol = widget.provider.stocks[0]['symbol'];
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Select rule type
        Row(
          children: [
            _buildTypeButton('SMA Crossover', 'SMA'),
            const SizedBox(width: 8),
            _buildTypeButton('RSI Index', 'RSI'),
            const SizedBox(width: 8),
            _buildTypeButton('Trailing Stop Loss', 'TRAILING'),
          ],
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Stock Symbol', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              if (widget.provider.stocks.isEmpty)
                const Text('Loading symbols...')
              else
                DropdownButtonFormField<String>(
                  value: _selectedSymbol,
                  dropdownColor: AppColors.surface,
                  decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(10)),
                  items: widget.provider.stocks
                      .map((s) => DropdownMenuItem<String>(
                            value: s['symbol'],
                            child: Text(s['symbol']),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedSymbol = val);
                  },
                ),
              const SizedBox(height: 16),

              if (_ruleType == 'SMA') ...[
                const Text('Crossover Horizon Period', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildChoiceChip('20-day SMA', _smaPeriod == '20', () => setState(() => _smaPeriod = '20')),
                    const SizedBox(width: 10),
                    _buildChoiceChip('50-day SMA', _smaPeriod == '50', () => setState(() => _smaPeriod = '50')),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Trigger Condition Direction', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildChoiceChip('Crosses ABOVE (Breakout)', _smaDirection == 'ABOVE', () => setState(() => _smaDirection = 'ABOVE')),
                    const SizedBox(width: 10),
                    _buildChoiceChip('Crosses BELOW (Support Breakdown)', _smaDirection == 'BELOW', () => setState(() => _smaDirection = 'BELOW')),
                  ],
                ),
              ] else if (_ruleType == 'RSI') ...[
                const Text('RSI Momentum Threshold limit', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildChoiceChip('Oversold limit (RSI <= 30)', _rsiThreshold == 30.0, () => setState(() => _rsiThreshold = 30.0)),
                    const SizedBox(width: 10),
                    _buildChoiceChip('Overbought limit (RSI >= 70)', _rsiThreshold == 70.0, () => setState(() => _rsiThreshold = 70.0)),
                  ],
                ),
              ] else if (_ruleType == 'TRAILING') ...[
                const Text('Dynamic Trailing Stop Loss margin', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildChoiceChip('3% Trailing SL', _trailPercent == 3.0, () => setState(() => _trailPercent = 3.0)),
                    const SizedBox(width: 8),
                    _buildChoiceChip('5% Trailing SL', _trailPercent == 5.0, () => setState(() => _trailPercent = 5.0)),
                    const SizedBox(width: 8),
                    _buildChoiceChip('8% Trailing SL', _trailPercent == 8.0, () => setState(() => _trailPercent = 8.0)),
                  ],
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _deployRule,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gainGreen, foregroundColor: Colors.black),
                  child: const Text('DEPLOY RULE PATTERN', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeButton(String label, String type) {
    final active = _ruleType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _ruleType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.gainGreen.withOpacity(0.12) : AppColors.surface,
            border: Border.all(color: active ? AppColors.gainGreen : Colors.white.withOpacity(0.04)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: active ? AppColors.gainGreen : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.gainGreen.withOpacity(0.08) : Colors.transparent,
          border: Border.all(color: active ? AppColors.gainGreen : Colors.white12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? AppColors.gainGreen : AppColors.textSecondary,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
