import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

// ─── Zone D: Portfolio, Wallet & Trading (8 Views) ───

class WalletManagerView extends StatefulWidget {
  final MarketProvider provider;
  const WalletManagerView({super.key, required this.provider});

  @override
  State<WalletManagerView> createState() => _WalletManagerViewState();
}

class _WalletManagerViewState extends State<WalletManagerView> {
  final _depositController = TextEditingController(text: '25000');
  final _withdrawController = TextEditingController(text: '10000');
  String _paymentMode = 'UPI';
  String _withdrawBank = 'State Bank of India';

  void _handleDeposit() {
    final double? amount = double.tryParse(_depositController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid deposit amount'), backgroundColor: AppColors.lossRed),
      );
      return;
    }

    widget.provider.depositCash(amount, 'Deposit via $_paymentMode');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Simulated credit of ₹${amount.toStringAsFixed(2)} successful!'), backgroundColor: AppColors.gainGreen),
    );
    _depositController.clear();
  }

  void _handleWithdraw() {
    final double? amount = double.tryParse(_withdrawController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid withdrawal amount'), backgroundColor: AppColors.lossRed),
      );
      return;
    }

    if (amount > widget.provider.walletBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient wallet balance'), backgroundColor: AppColors.lossRed),
      );
      return;
    }

    widget.provider.withdrawCash(amount, 'Withdrawal to $_withdrawBank');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Simulated withdrawal of ₹${amount.toStringAsFixed(2)} successful!'), backgroundColor: AppColors.gainGreen),
    );
    _withdrawController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final logs = widget.provider.walletLogs;

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Balance Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.surface, Color(0xFF1F2D44)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SIMULATED WALLET BALANCE', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                '₹${widget.provider.walletBalance.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.gainGreen),
              ),
              const SizedBox(height: 4),
              const Text('Used as margin cash for rule alerts and simulated trades.', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Deposit Cash Form (UPI simulator)
        const Text('Deposit Simulated Cash', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _depositController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _paymentMode,
                      decoration: const InputDecoration(labelText: 'Method', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
                      dropdownColor: AppColors.surface,
                      items: const [
                        DropdownMenuItem(value: 'UPI', child: Text('UPI / GPay')),
                        DropdownMenuItem(value: 'NETBANKING', child: Text('Net Banking')),
                        DropdownMenuItem(value: 'CARD', child: Text('Debit Card')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _paymentMode = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _handleDeposit,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.gainGreen, foregroundColor: Colors.black),
                  child: const Text('SIMULATE UPI DEPOSIT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Withdraw Cash Form (Bank simulator)
        const Text('Withdraw Simulated Cash', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _withdrawController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder(), contentPadding: EdgeInsets.all(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _withdrawBank,
                      decoration: const InputDecoration(labelText: 'Bank', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12)),
                      dropdownColor: AppColors.surface,
                      items: const [
                        DropdownMenuItem(value: 'State Bank of India', child: Text('SBI Bank')),
                        DropdownMenuItem(value: 'HDFC Bank', child: Text('HDFC Bank')),
                        DropdownMenuItem(value: 'ICICI Bank', child: Text('ICICI Bank')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _withdrawBank = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _handleWithdraw,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lossRed.withOpacity(0.15),
                    foregroundColor: AppColors.lossRed,
                    elevation: 0,
                    side: const BorderSide(color: AppColors.lossRed, width: 0.5),
                  ),
                  child: const Text('SIMULATE BANK WITHDRAWAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Transaction Logs Ledger
        const Text('Wallet Margin Transaction History', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (logs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: Text('No wallet transactions logged.', style: TextStyle(color: AppColors.textMuted))),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.04)),
            itemBuilder: (context, index) {
              final log = logs[index];
              final isCredit = log['type'] == 'CREDIT';
              final amount = log['amount'] as double;
              final String dateStr = log['date'] != null ? DateTime.parse(log['date']).toLocal().toString().substring(5, 16) : '';

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isCredit ? AppColors.gainGreen : AppColors.lossRed).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(isCredit ? Icons.add : Icons.remove, color: isCredit ? AppColors.gainGreen : AppColors.lossRed, size: 16),
                ),
                title: Text(log['description'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                subtitle: Text(dateStr, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                trailing: Text(
                  '${isCredit ? "+" : "-"}₹${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCredit ? AppColors.gainGreen : AppColors.lossRed,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class TaxReportView extends StatelessWidget {
  final MarketProvider provider;
  const TaxReportView({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    // Standard Capital Gains calculations based on paper trades sold
    final trades = provider.trades.where((t) => t['type'] == 'SELL').toList();

    double totalRealized = 0.0;
    if (provider.portfolio != null) {
      totalRealized = (provider.portfolio!['totalRealizedPnL'] as num).toDouble();
    }

    // Heuristically distribute between STCG (75%) and LTCG (25%) for simulation
    final double stcg = totalRealized > 0 ? totalRealized * 0.75 : totalRealized;
    final double ltcg = totalRealized > 0 ? totalRealized * 0.25 : 0.0;

    // STCG Tax is 15% in India, LTCG is 10% on gains exceeding 1 Lakh
    final double stcgTax = stcg > 0 ? stcg * 0.15 : 0.0;
    final double ltcgTax = ltcg > 100000 ? (ltcg - 100000) * 0.10 : 0.0;
    final double totalTax = stcgTax + ltcgTax;

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Summary Metrics
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
                  Icon(Icons.receipt_long, color: AppColors.gainGreen, size: 20),
                  SizedBox(width: 8),
                  Text('Estimated Capital Gains Tax Audit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 18),
              _buildReportRow('Net Realized Capital P&L', '₹${totalRealized.toStringAsFixed(2)}', totalRealized >= 0 ? AppColors.gainGreen : AppColors.lossRed, bold: true),
              const Divider(color: Colors.white12, height: 16),
              _buildReportRow('Short-Term Capital Gains (STCG)', '₹${stcg.toStringAsFixed(2)}', Colors.white70),
              _buildReportRow('Long-Term Capital Gains (LTCG)', '₹${ltcg.toStringAsFixed(2)}', Colors.white70),
              const Divider(color: Colors.white12, height: 16),
              _buildReportRow('Simulated STCG Tax Due (15%)', '₹${stcgTax.toStringAsFixed(2)}', AppColors.lossRed),
              _buildReportRow('Simulated LTCG Tax Due (10%)', '₹${ltcgTax.toStringAsFixed(2)}', AppColors.lossRed),
              const Divider(color: Colors.white12, height: 16),
              _buildReportRow('Total Estimated Tax Liability', '₹${totalTax.toStringAsFixed(2)}', AppColors.lossRed, bold: true),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Closed Trades Table
        const Text('Simulated Capital Gains Tax Ledger', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (trades.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(child: Text('No closed positions recorded. Sell shares to calculate tax.', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
          )
        else
          Container(
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(3),
              },
              children: [
                const TableRow(
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
                  children: [
                    Padding(padding: EdgeInsets.all(10), child: Text('Stock', style: TextStyle(fontSize: 10, color: AppColors.textSecondary))),
                    Padding(padding: EdgeInsets.all(10), child: Text('Shares Sold', style: TextStyle(fontSize: 10, color: AppColors.textSecondary))),
                    Padding(padding: EdgeInsets.all(10), child: Text('Realized P&L', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, color: AppColors.textSecondary))),
                  ],
                ),
                ...trades.map((t) {
                  final pnl = (t['realizedPnL'] as num?)?.toDouble() ?? 0.0;
                  final pos = pnl >= 0;
                  return TableRow(
                    children: [
                      Padding(padding: const EdgeInsets.all(10), child: Text(t['symbol'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      Padding(padding: const EdgeInsets.all(10), child: Text('${t['quantity']}', style: const TextStyle(fontSize: 12))),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          '${pos ? "+" : ""}₹${pnl.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: pos ? AppColors.gainGreen : AppColors.lossRed),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReportRow(String label, String value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
