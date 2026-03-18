import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';

class SummaryCard extends StatelessWidget {
  final List<TransactionModel> transactions;

  const SummaryCard({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final totalBalance = _calculateBalance(transactions);
    final cashBalance = _calculateBalance(transactions, paymentMethod: 'cash');
    final bankBalance = _calculateBalance(transactions, paymentMethod: 'bank');
    final totalIncome = _calculateTotal(transactions, 'income');
    final totalExpense = _calculateTotal(transactions, 'expense');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Text(
                    currencyFormat.format(totalBalance),
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSimpleSummary(
                    label: 'Pemasukan',
                    amount: totalIncome,
                    icon: Icons.arrow_downward,
                    color: Colors.greenAccent.shade400,
                  ),
                ),
                Container(
                  height: 32,
                  width: 1,
                  color: Colors.white.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildSimpleSummary(
                    label: 'Pengeluaran',
                    amount: totalExpense,
                    icon: Icons.arrow_upward,
                    color: Colors.orangeAccent.shade200,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSmallInfo('Cash', cashBalance, Icons.money),
              _buildSmallInfo('Bank', bankBalance, Icons.account_balance),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSummary({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                currencyFormat.format(amount),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallInfo(String label, double amount, IconData icon) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label: ${currencyFormat.format(amount)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  double _calculateBalance(
    List<TransactionModel> transactions, {
    String? paymentMethod,
  }) {
    double balance = 0;
    for (var trx in transactions) {
      if (paymentMethod != null && trx.paymentMethod != paymentMethod) continue;
      if (trx.type == 'income') {
        balance += trx.amount;
      } else {
        balance -= trx.amount;
      }
    }
    return balance;
  }

  double _calculateTotal(List<TransactionModel> transactions, String type) {
    return transactions
        .where((trx) => trx.type == type)
        .fold(0, (sum, item) => sum + item.amount);
  }
}
