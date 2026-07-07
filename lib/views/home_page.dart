import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/transaction_cubit.dart';
import '../blocs/recurring_cubit.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_item.dart';
import '../widgets/summary_card.dart';
import 'add_transaction_page.dart';
import 'statistics_page.dart';
import 'recurring_transactions_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _filterType = 'Semua'; // Semua, Pemasukan, Pengeluaran
  String _dateFilter = 'Semua'; // Semua, Hari Ini, Minggu Ini, Bulan Ini

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Money Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.repeat_on_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecurringTransactionsPage(),
                ),
              );
            },
          ),
          BlocBuilder<TransactionCubit, List<TransactionModel>>(
            builder: (context, transactions) {
              return IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          StatisticsPage(transactions: transactions),
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TransactionCubit>().load();
              context.read<RecurringCubit>().load();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
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
          child: BlocBuilder<TransactionCubit, List<TransactionModel>>(
            builder: (context, allTransactions) {
              final now = DateTime.now();
              // Apply filtering and search
              final transactions = allTransactions.where((trx) {
                final matchesSearch = trx.title.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                );
                final matchesFilter =
                    _filterType == 'Semua' ||
                    (_filterType == 'Pemasukan' && trx.type == 'income') ||
                    (_filterType == 'Pengeluaran' && trx.type == 'expense');

                bool matchesDate = true;
                if (_dateFilter == 'Hari Ini') {
                  matchesDate =
                      trx.date.day == now.day &&
                      trx.date.month == now.month &&
                      trx.date.year == now.year;
                } else if (_dateFilter == 'Minggu Ini') {
                  final startOfWeek = now.subtract(
                    Duration(days: now.weekday - 1),
                  );
                  final endOfWeek = startOfWeek.add(const Duration(days: 6));
                  matchesDate =
                      trx.date.isAfter(
                        startOfWeek.subtract(const Duration(days: 1)),
                      ) &&
                      trx.date.isBefore(endOfWeek.add(const Duration(days: 1)));
                } else if (_dateFilter == 'Bulan Ini') {
                  matchesDate =
                      trx.date.month == now.month && trx.date.year == now.year;
                }

                return matchesSearch && matchesFilter && matchesDate;
              }).toList();

              return Column(
                children: [
                  const SizedBox(height: kToolbarHeight + 16),
                  SummaryCard(transactions: allTransactions),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search and Filter Bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                          child: Column(
                            children: [
                              TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Cari transaksi...',
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 0,
                                    horizontal: 16,
                                  ),
                                ),
                                onChanged: (value) => setState(() {}),
                              ),
                              const SizedBox(height: 12),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildFilterChip('Semua'),
                                    const SizedBox(width: 8),
                                    _buildFilterChip('Pemasukan'),
                                    const SizedBox(width: 8),
                                    _buildFilterChip('Pengeluaran'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _buildDateFilterChip('Semua'),
                                    const SizedBox(width: 8),
                                    _buildDateFilterChip('Hari Ini'),
                                    const SizedBox(width: 8),
                                    _buildDateFilterChip('Minggu Ini'),
                                    const SizedBox(width: 8),
                                    _buildDateFilterChip('Bulan Ini'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Transaksi',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              if (transactions.isNotEmpty)
                                Text(
                                  '${transactions.length} ditemukan',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: transactions.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 80,
                                        color: Colors.grey.shade200,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchController.text.isNotEmpty ||
                                                _filterType != 'Semua'
                                            ? 'Tidak ada transaksi yang sesuai'
                                            : 'Belum ada transaksi',
                                        style: textTheme.titleMedium?.copyWith(
                                          color: Colors.grey.shade400,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Mulai catat keuanganmu hari ini!',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 16,
                                  ),
                                  itemCount: transactions.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(
                                        height: 1,
                                        indent: 80,
                                        endIndent: 24,
                                        color: Color(0xFFF1F5F9),
                                      ),
                                  itemBuilder: (context, index) {
                                    final transaction = transactions[index];
                                    return TransactionItem(
                                      transaction: transaction,
                                      onTap: () async {
                                        final cubit = context
                                            .read<TransactionCubit>();
                                        final allTransactions = cubit.state;
                                        final actualIndex = allTransactions
                                            .indexOf(transaction);

                                        if (actualIndex != -1) {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  AddTransactionPage(
                                                    transaction: transaction,
                                                    index: actualIndex,
                                                  ),
                                            ),
                                          );
                                          if (context.mounted) {
                                            context
                                                .read<TransactionCubit>()
                                                .load();
                                          }
                                        }
                                      },
                                      onDelete: () {
                                        _showDeleteDialog(context, transaction);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionPage()),
          );
          // Refresh list after adding
          if (context.mounted) {
            context.read<TransactionCubit>().load();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterType == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filterType = label;
          });
        }
      },
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _buildDateFilterChip(String label) {
    final isSelected = _dateFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _dateFilter = label;
          });
        }
      },
      selectedColor: Theme.of(context).colorScheme.secondary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showDeleteDialog(BuildContext context, TransactionModel transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Hapus Transaksi?'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${transaction.title}"?\nTindakan ini tidak dapat dibatalkan.',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              final cubit = context.read<TransactionCubit>();
              final allTransactions = cubit.state;
              final actualIndex = allTransactions.indexOf(transaction);
              if (actualIndex != -1) {
                cubit.delete(actualIndex);
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${transaction.title}" dihapus'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
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
}
