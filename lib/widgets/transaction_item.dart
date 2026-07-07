import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../utils/categories.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.onDelete,
    this.onTap,
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

    return InkWell(
      onTap: onTap,
      onLongPress: onDelete,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          transaction.paymentMethod == 'cash'
                              ? 'Tunai'
                              : 'Bank',
                          style: textTheme.labelSmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${transaction.category} • ${DateFormat('dd MMM yyyy', 'id_ID').format(transaction.date)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'} ${currencyFormat.format(transaction.amount).replaceAll('Rp ', '')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isIncome
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
                Text(
                  isIncome ? 'Pemasukan' : 'Pengeluaran',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
                tooltip: 'Hapus transaksi',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
