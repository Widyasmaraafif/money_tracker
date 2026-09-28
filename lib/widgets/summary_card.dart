import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';
import '../utils/wallets.dart';

class SummaryCard extends StatefulWidget {
  final List<TransactionModel> transactions;

  const SummaryCard({super.key, required this.transactions});

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard> {
  bool _obscured = false;

  String _hide(String value) {
    // Keep length roughly similar, hide digits only.
    return value.replaceAll(RegExp(r'[0-9]'), '•');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Single pass aggregation: was 4 full loops before.
    double totalBalance = 0;
    double totalIncome = 0;
    double totalExpense = 0;
    for (final trx in widget.transactions) {
      if (trx.type == 'transfer') continue;
      final signed = trx.type == 'income' ? trx.amount : -trx.amount;
      totalBalance += signed;
      if (trx.type == 'income') {
        totalIncome += trx.amount;
      } else {
        totalExpense += trx.amount;
      }
    }
    final balances = Wallets.balances(widget.transactions);
    final cashBalance = balances[Wallets.cash] ?? 0;
    final bankBalance = balances[Wallets.bank] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Saldo',
                style: textTheme.titleSmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _obscured
                          ? _hide(formatRupiah(totalBalance))
                          : formatRupiah(totalBalance),
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _obscured = !_obscured),
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white.withOpacity(0.9),
                      size: 22,
                    ),
                    tooltip: _obscured
                        ? 'Tampilkan nominal'
                        : 'Sembunyikan nominal',
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSimpleStat(
                context,
                'Tunai',
                _obscured
                    ? _hide(formatPlain(cashBalance))
                    : formatPlain(cashBalance),
                Icons.wallet_rounded,
                Colors.orangeAccent,
              ),
              const SizedBox(width: 16),
              _buildSimpleStat(
                context,
                'Bank',
                _obscured
                    ? _hide(formatPlain(bankBalance))
                    : formatPlain(bankBalance),
                Icons.account_balance_rounded,
                Colors.lightBlueAccent,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStat(
                context,
                'Pemasukan',
                _obscured
                    ? _hide(formatRupiah(totalIncome))
                    : formatRupiah(totalIncome),
                Icons.arrow_downward_rounded,
                Colors.greenAccent,
              ),
              const SizedBox(width: 16),
              _buildStat(
                context,
                'Pengeluaran',
                _obscured
                    ? _hide(formatRupiah(totalExpense))
                    : formatRupiah(totalExpense),
                Icons.arrow_upward_rounded,
                Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
