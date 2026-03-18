import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import 'summary_item.dart';

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
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Saldo',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(totalBalance),
            style: textTheme.displaySmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SummaryItem(
                  label: 'Cash',
                  amount: cashBalance,
                  icon: Icons.wallet,
                  color: colorScheme.onPrimary,
                ),
                const VerticalDivider(
                  color: Colors.white54,
                  thickness: 1,
                  width: 1,
                  indent: 8,
                  endIndent: 8,
                ),
                SummaryItem(
                  label: 'Bank',
                  amount: bankBalance,
                  icon: Icons.account_balance,
                  color: colorScheme.onPrimary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SummaryItem(
                  label: 'Pemasukan',
                  amount: totalIncome,
                  icon: Icons.arrow_upward,
                  color: Colors.green.shade300,
                ),
                const VerticalDivider(
                  color: Colors.white54,
                  thickness: 1,
                  width: 1,
                  indent: 8,
                  endIndent: 8,
                ),
                SummaryItem(
                  label: 'Pengeluaran',
                  amount: totalExpense,
                  icon: Icons.arrow_downward,
                  color: Colors.red.shade300,
                ),
              ],
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
