import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/transaction_cubit.dart';
import '../blocs/recurring_cubit.dart';
import '../blocs/budget_cubit.dart';
import '../blocs/saving_cubit.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../widgets/transaction_item.dart';
import '../widgets/summary_card.dart';
import '../widgets/streak_card.dart';
import 'add_transaction_page.dart';
import 'add_transfer_page.dart';
import 'statistics_page.dart';
import 'recurring_transactions_page.dart';
import 'budgets_page.dart';
import 'savings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _filterType = 'Semua'; // Semua, Pemasukan, Pengeluaran, Transfer
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Money Tracker'),
        centerTitle: false,
        titleSpacing: 20,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
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
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.repeat_on_rounded),
            tooltip: 'Transaksi Rutin',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RecurringTransactionsPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.savings_outlined),
            tooltip: 'Anggaran',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Tabungan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SavingsPage()),
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
        ],
      ),
      body: Container(
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
        child: SafeArea(
          top: false,
          bottom: false,
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
                    (_filterType == 'Pengeluaran' && trx.type == 'expense') ||
                    (_filterType == 'Transfer' && trx.type == 'transfer');

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
              }).toList()..sort((a, b) => b.date.compareTo(a.date));

              final hasActiveFilter =
                  _searchController.text.isNotEmpty ||
                  _filterType != 'Semua' ||
                  _dateFilter != 'Semua';

              return RefreshIndicator(
                // Baru refresh setelah ditarik melewati 100px.
                displacement: 100,
                edgeOffset: 0,
                triggerMode: RefreshIndicatorTriggerMode.anywhere,
                onRefresh: () async {
                  context.read<TransactionCubit>().load();
                  context.read<RecurringCubit>().load();
                  context.read<BudgetCubit>().load();
                  context.read<SavingCubit>().load();
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(
                      child: SummaryCard(transactions: allTransactions),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(
                      child: StreakCard(transactions: allTransactions),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(
                      child: _buildBudgetAlert(context, allTransactions),
                    ),
                    // Pinned filter header: stays visible while the list scrolls.
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _FilterHeaderDelegate(
                        minHeight: 196,
                        maxHeight: 196,
                        child: Container(
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
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  12,
                                  20,
                                  0,
                                ),
                                child: SizedBox(
                                  height: 48,
                                  child: TextField(
                                    controller: _searchController,
                                    textInputAction: TextInputAction.search,
                                    decoration: InputDecoration(
                                      hintText: 'Cari transaksi...',
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        size: 22,
                                      ),
                                      suffixIcon:
                                          _searchController.text.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.clear,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                                setState(() {});
                                              },
                                            )
                                          : null,
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 16,
                                          ),
                                    ),
                                    onChanged: (value) => setState(() {}),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _buildDropdown(
                                        value: _filterType,
                                        prefixIcon: Icons.swap_vert_rounded,
                                        items: const [
                                          'Semua',
                                          'Pemasukan',
                                          'Pengeluaran',
                                          'Transfer',
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() => _filterType = value);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _buildDropdown(
                                        value: _dateFilter,
                                        prefixIcon:
                                            Icons.calendar_month_rounded,
                                        items: const [
                                          'Semua',
                                          'Hari Ini',
                                          'Minggu Ini',
                                          'Bulan Ini',
                                        ],
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() => _dateFilter = value);
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  8,
                                  16,
                                  8,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 10,
                                      ),
                                      child: Text(
                                        'Transaksi',
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF1E293B),
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
                                        color: colorScheme.primary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${transactions.length}',
                                        style: textTheme.labelSmall?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (hasActiveFilter)
                                      TextButton.icon(
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _filterType = 'Semua';
                                            _dateFilter = 'Semua';
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.restart_alt,
                                          size: 16,
                                        ),
                                        label: const Text('Reset'),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (transactions.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyTransactionView(),
                      )
                    else ...[
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 0),
                        sliver: SliverList.separated(
                          itemCount: transactions.length,
                          separatorBuilder: (context, index) => Container(
                            color: Colors.white,
                            child: const Divider(
                              height: 1,
                              indent: 80,
                              endIndent: 24,
                              color: Color(0xFFF1F5F9),
                            ),
                          ),
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            final isFirst = index == 0;
                            final isLast = index == transactions.length - 1;
                            return Container(
                              color: Colors.white,
                              padding: EdgeInsets.only(bottom: isLast ? 20 : 0),
                              child: Container(
                                margin: EdgeInsets.fromLTRB(
                                  12,
                                  isFirst ? 12 : 4,
                                  12,
                                  isLast ? 4 : 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFF1F5F9),
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: TransactionItem(
                                  transaction: transaction,
                                  onTap: () async {
                                    final cubit = context
                                        .read<TransactionCubit>();
                                    final actualIndex = cubit.state.indexOf(
                                      transaction,
                                    );

                                    if (actualIndex != -1) {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              transaction.type == 'transfer'
                                              ? AddTransferPage(
                                                  transaction: transaction,
                                                  index: actualIndex,
                                                )
                                              : AddTransactionPage(
                                                  transaction: transaction,
                                                  index: actualIndex,
                                                ),
                                        ),
                                      );
                                      if (context.mounted) {
                                        context.read<TransactionCubit>().load();
                                      }
                                    }
                                  },
                                  onDelete: () {
                                    _showDeleteDialog(context, transaction);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // White filler to bottom edge (covers gradient + nav bar area).
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white,
                          height: 90 + MediaQuery.of(context).padding.bottom,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'transfer',
            tooltip: 'Transfer dompet',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTransferPage(),
                ),
              );
              if (context.mounted) {
                context.read<TransactionCubit>().load();
              }
            },
            child: const Icon(Icons.swap_horiz_rounded),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddTransactionPage(),
                ),
              );
              // Refresh list after adding
              if (context.mounted) {
                context.read<TransactionCubit>().load();
              }
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetAlert(
    BuildContext context,
    List<TransactionModel> allTransactions,
  ) {
    final now = DateTime.now();
    return BlocBuilder<BudgetCubit, List<BudgetModel>>(
      builder: (context, budgets) {
        final current = budgets
            .where((b) => b.month == now.month && b.year == now.year)
            .toList();

        if (current.isEmpty) return const SizedBox.shrink();

        int overCount = 0;
        int nearCount = 0;
        for (final b in current) {
          if (b.limit <= 0) continue;
          final p = b.spent(allTransactions) / b.limit;
          if (p > 1.0) {
            overCount++;
          } else if (p >= 0.8) {
            nearCount++;
          }
        }

        if (overCount == 0 && nearCount == 0) {
          return const SizedBox.shrink();
        }

        final isOver = overCount > 0;
        final message = isOver
            ? '$overCount anggaran terlampaui!'
            : '$nearCount anggaran hampir habis (≥80%)';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetsPage()),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isOver ? Colors.red.shade600 : Colors.orange.shade600,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isOver ? Colors.red : Colors.orange).withOpacity(
                      0.3,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    isOver ? Icons.warning_rounded : Icons.info_outline_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdown({
    required String value,
    required IconData prefixIcon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: false,
          itemHeight: 52,
          borderRadius: BorderRadius.circular(16),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 24),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Row(
                    children: [
                      Icon(prefixIcon, size: 20, color: Colors.grey.shade600),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(item, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, TransactionModel transaction) {
    final cubit = context.read<TransactionCubit>();
    final actualIndex = cubit.state.indexOf(transaction);
    if (actualIndex == -1) return;

    // Salin data untuk Undo (objek asli ikut terhapus dari box).
    final backup = TransactionModel(
      title: transaction.title,
      amount: transaction.amount,
      type: transaction.type,
      date: transaction.date,
      category: transaction.category,
      paymentMethod: transaction.paymentMethod,
      toPaymentMethod: transaction.toPaymentMethod,
    );
    cubit.delete(actualIndex);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${backup.title}" dihapus'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Urungkan',
          onPressed: () {
            cubit.restoreAt(actualIndex, backup);
          },
        ),
      ),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  const _FilterHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.minHeight != minHeight ||
        oldDelegate.maxHeight != maxHeight;
  }
}

class _EmptyTransactionView extends StatelessWidget {
  const _EmptyTransactionView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        24,
        48,
        24,
        48 + MediaQuery.of(context).padding.bottom,
      ),
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
            'Belum ada transaksi',
            style: textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai catat keuanganmu hari ini!',
            style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
