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
          Row(
            children: [
              _buildSimpleStat(
                context,
                'Tunai',
                currencyFormat.format(cashBalance),
                Icons.wallet_rounded,
                Colors.orangeAccent,
              ),
              const SizedBox(width: 16),
              _buildSimpleStat(
                context,
                'Bank',
                currencyFormat.format(bankBalance),
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
                currencyFormat.format(totalIncome),
                Icons.arrow_downward_rounded,
                Colors.greenAccent,
              ),
              const SizedBox(width: 16),
              _buildStat(
                context,
                'Pengeluaran',
                currencyFormat.format(totalExpense),
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
                    value.replaceAll('Rp ', ''),
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
