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
    final expenseRatio = totalIncome > 0 ? totalExpense / totalIncome : 0.0;
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
          // Progress bar for expense ratio
          if (totalIncome > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rasio Pengeluaran',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Text(
                  '${(expenseRatio * 100).toStringAsFixed(1)}%',
                  style: textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: expenseRatio.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  expenseRatio > 0.8 ? Colors.redAccent : Colors.white70,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 20),
          ],
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMethodSummary(
                label: 'Tunai',
                amount: cashBalance,
                icon: Icons.wallet_outlined,
              ),
              _buildMethodSummary(
                label: 'Bank',
                amount: bankBalance,
                icon: Icons.account_balance_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSummary({
    required String label,
    required double amount,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        Text(
          NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp',
            decimalDigits: 0,
          ).format(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleSummary({
    required String label,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            ).format(amount),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  double _calculateBalance(
    List<TransactionModel> transactions, {
    String? paymentMethod,
  }) {
    double balance = 0;
    for (var trx in transactions) {
      if (paymentMethod != null && trx.paymentMethod != paymentMethod) {
        continue;
      }
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
        .fold(0, (sum, trx) => sum + trx.amount);
  }
}
