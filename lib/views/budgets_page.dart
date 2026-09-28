import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/budget_cubit.dart';
import '../blocs/transaction_cubit.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../widgets/budget_item.dart';
import 'add_budget_page.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  late int _month;
  late int _year;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = now.month;
    _year = now.year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BudgetCubit>().loadForMonth(_month, _year);
      }
    });
  }

  void _changeMonth(int delta) {
    var newMonth = _month + delta;
    var newYear = _year;
    if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    } else if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    }
    setState(() {
      _month = newMonth;
      _year = newYear;
    });
    context.read<BudgetCubit>().loadForMonth(_month, _year);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final periodLabel = DateFormat(
      'MMMM yyyy',
      'id_ID',
    ).format(DateTime(_year, _month));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anggaran'),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
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
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Text(
                      periodLabel,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
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
                  child: BlocBuilder<TransactionCubit, List<TransactionModel>>(
                    builder: (context, transactions) {
                      return BlocBuilder<BudgetCubit, List<BudgetModel>>(
                        builder: (context, allBudgets) {
                          final budgets = allBudgets
                              .where(
                                (b) => b.month == _month && b.year == _year,
                              )
                              .toList();

                          if (budgets.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.savings_outlined,
                                    size: 80,
                                    color: Colors.grey.shade200,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Belum ada anggaran',
                                    style: textTheme.titleMedium?.copyWith(
                                      color: Colors.grey.shade400,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Atur batas pengeluaran per kategori!',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
                            itemCount: budgets.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final budget = budgets[index];
                              return BudgetItem(
                                budget: budget,
                                transactions: transactions,
                                onTap: () async {
                                  final cubit = context.read<BudgetCubit>();
                                  final actualIndex = cubit.indexOf(budget);
                                  if (actualIndex != -1) {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddBudgetPage(
                                          budget: budget,
                                          index: actualIndex,
                                        ),
                                      ),
                                    );
                                    if (context.mounted) {
                                      context.read<BudgetCubit>().loadForMonth(
                                        _month,
                                        _year,
                                      );
                                    }
                                  }
                                },
                                onDelete: () {
                                  _showDeleteDialog(context, budget);
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBudgetPage()),
          );
          if (context.mounted) {
            context.read<BudgetCubit>().loadForMonth(_month, _year);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, BudgetModel budget) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Hapus Anggaran?'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus anggaran "${budget.category}"?',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              final cubit = context.read<BudgetCubit>();
              final actualIndex = cubit.indexOf(budget);
              if (actualIndex != -1) {
                cubit.delete(actualIndex);
                cubit.loadForMonth(_month, _year);
              }
              Navigator.pop(dialogContext);
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
