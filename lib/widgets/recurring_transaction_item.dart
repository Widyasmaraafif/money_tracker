import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/recurring_transaction_model.dart';
import '../utils/categories.dart';

class RecurringTransactionItem extends StatelessWidget {
  final RecurringTransactionModel transaction;
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkOccurred;

  const RecurringTransactionItem({
    super.key,
    required this.transaction,
    required this.index,
    this.onTap,
    this.onDelete,
    this.onMarkOccurred,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final category = TransactionCategory.getByName(transaction.category);
    String recurrenceLabel = '';
    switch (transaction.recurrenceType) {
      case RecurrenceType.daily:
        recurrenceLabel = 'Harian';
        break;
      case RecurrenceType.weekly:
        recurrenceLabel = 'Mingguan';
        break;
      case RecurrenceType.monthly:
        recurrenceLabel = 'Bulanan';
        break;
      case RecurrenceType.yearly:
        recurrenceLabel = 'Tahunan';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(category.icon, color: category.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: transaction.isActive
                                ? Colors.green.shade100
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            transaction.isActive ? 'Aktif' : 'Nonaktif',
                            style: textTheme.bodySmall?.copyWith(
                              color: transaction.isActive
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            recurrenceLabel,
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'} ${currencyFormat.format(transaction.amount).replaceAll('Rp ', '')}',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isIncome ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                'Selanjutnya: ${DateFormat('dd MMM yyyy', 'id_ID').format(transaction.nextOccurrence)}',
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500,
                ),
              ),
              if (transaction.hasReminder) ...[
                const SizedBox(width: 16),
                Icon(
                  Icons.notifications_active_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ],
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.check_circle_outline_rounded),
                color: Colors.green.shade600,
                onPressed: onMarkOccurred,
                tooltip: 'Tandai Telah Terjadi',
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                color: colorScheme.primary,
                onPressed: onTap,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                color: Colors.red.shade600,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
