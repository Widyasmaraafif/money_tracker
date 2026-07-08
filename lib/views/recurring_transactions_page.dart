import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/recurring_cubit.dart';
import '../blocs/transaction_cubit.dart';
import '../models/recurring_transaction_model.dart';
import '../models/transaction_model.dart';
import '../widgets/recurring_transaction_item.dart';
import 'add_recurring_transaction_page.dart';
import '../services/notification_service.dart';

class RecurringTransactionsPage extends StatefulWidget {
  const RecurringTransactionsPage({super.key});

  @override
  State<RecurringTransactionsPage> createState() =>
      _RecurringTransactionsPageState();
}

class _RecurringTransactionsPageState extends State<RecurringTransactionsPage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Transaksi Rutin'),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
              colorScheme.secondary.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BlocBuilder<RecurringCubit, List<RecurringTransactionModel>>(
          builder: (context, recurringTransactions) {
            return Column(
              children: [
                const SizedBox(height: kToolbarHeight + 20),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: recurringTransactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.repeat_on_rounded,
                                  size: 80,
                                  color: Colors.grey.shade200,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada transaksi rutin',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tambahkan transaksi rutinmu!',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            itemCount: recurringTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = recurringTransactions[index];
                              return RecurringTransactionItem(
                                transaction: transaction,
                                index: index,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddRecurringTransactionPage(
                                        transaction: transaction,
                                        index: index,
                                      ),
                                    ),
                                  );
                                  if (context.mounted) {
                                    context
                                        .read<RecurringCubit>()
                                        .load();
                                  }
                                },
                                onDelete: () {
                                  _showDeleteDialog(context, transaction, index);
                                },
                                onMarkOccurred: () {
                                  _showMarkOccurredDialog(
                                      context, transaction, index);
                                },
                                onToggleActive: () {
                                  context.read<RecurringCubit>().toggleActive(index);
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddRecurringTransactionPage(),
            ),
          );
          if (context.mounted) {
            context.read<RecurringCubit>().load();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    RecurringTransactionModel transaction,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Hapus Transaksi Rutin?'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${transaction.title}"?',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              context.read<RecurringCubit>().delete(index);
              await NotificationService.cancelReminder(index + 1000);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showMarkOccurredDialog(
    BuildContext context,
    RecurringTransactionModel recurringTransaction,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, color: Colors.green),
            SizedBox(width: 12),
            Text('Tandai Telah Terjadi?'),
          ],
        ),
        content: Text(
          'Apakah Anda ingin menambahkan transaksi "${recurringTransaction.title}" ke transaksi biasa?',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              final transaction = TransactionModel(
                title: recurringTransaction.title,
                amount: recurringTransaction.amount,
                type: recurringTransaction.type,
                date: DateTime.now(),
                category: recurringTransaction.category,
                paymentMethod: recurringTransaction.paymentMethod,
              );
              context.read<TransactionCubit>().add(transaction);
              context.read<RecurringCubit>().markAsOccurred(index);
              if (recurringTransaction.hasReminder) {
                final updatedTransaction =
                    context.read<RecurringCubit>().state[index];
                await NotificationService.scheduleReminder(
                    updatedTransaction, index + 1000);
              }
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaksi ditambahkan!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade50,
              foregroundColor: Colors.green,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Tambahkan'),
          ),
        ],
      ),
    );
  }
}
