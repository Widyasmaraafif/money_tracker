import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/transaction_cubit.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_item.dart';
import 'add_transaction_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Money Tracker', style: textTheme.headlineSmall),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<TransactionCubit, List<TransactionModel>>(
        builder: (context, transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Text('Belum ada transaksi. Tambahkan sekarang!'),
            );
          }

          final totalBalance = _calculateBalance(transactions);
          final totalIncome = _calculateTotal(transactions, 'income');
          final totalExpense = _calculateTotal(transactions, 'expense');

          return Column(
            children: [
              _buildSummaryCard(
                context,
                totalBalance,
                totalIncome,
                totalExpense,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Text(
                      'Transaksi Terakhir',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return TransactionItem(
                      transaction: transaction,
                      onDelete: () {
                        context.read<TransactionCubit>().delete(index);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    double totalBalance,
    double totalIncome,
    double totalExpense,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
    );
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
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
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(totalBalance),
            style: textTheme.displaySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                context,
                'Pemasukan',
                totalIncome,
                Icons.arrow_upward,
                Colors.green,
              ),
              _buildSummaryItem(
                context,
                'Pengeluaran',
                totalExpense,
                Icons.arrow_downward,
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    double amount,
    IconData icon,
    Color iconColor,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
    );
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              currencyFormat.format(amount),
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _calculateBalance(List<TransactionModel> transactions) {
    double balance = 0;
    for (var trx in transactions) {
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
