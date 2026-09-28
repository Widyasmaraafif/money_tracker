import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/saving_cubit.dart';
import '../blocs/transaction_cubit.dart';
import '../models/saving_goal_model.dart';
import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';
import 'add_saving_page.dart';

class SavingDetailPage extends StatelessWidget {
  final SavingGoalModel goal;
  final int index;

  const SavingDetailPage({super.key, required this.goal, required this.index});

  SavingGoalModel _current(List<SavingGoalModel> goals) {
    try {
      return goals.firstWhere((g) => g.createdAt == goal.createdAt);
    } catch (_) {
      return goal;
    }
  }

  int _monthsInclusive(DateTime from, DateTime to) {
    final diff = (to.year * 12 + to.month) - (from.year * 12 + from.month) + 1;
    return diff < 1 ? 1 : diff;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tabungan'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: 'Edit tabungan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddSavingPage(
                    goal: _current(context.read<SavingCubit>().state),
                    index: index,
                  ),
                ),
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
          child: BlocBuilder<SavingCubit, List<SavingGoalModel>>(
            builder: (context, goals) {
              final current = _current(goals);
              return BlocBuilder<TransactionCubit, List<TransactionModel>>(
                builder: (context, transactions) {
                  final setorTitle = 'Setor ke ${current.name}';
                  final tarikTitle = 'Tarik dari ${current.name}';
                  final deposits = transactions.where(
                    (t) =>
                        t.type == 'expense' &&
                        t.category == 'Tabungan' &&
                        t.title == setorTitle,
                  );
                  final withdrawals = transactions.where(
                    (t) =>
                        t.type == 'income' &&
                        t.category == 'Tabungan' &&
                        t.title == tarikTitle,
                  );
                  final totalSetor = deposits.fold<double>(
                    0,
                    (sum, t) => sum + t.amount,
                  );
                  final totalTarik = withdrawals.fold<double>(
                    0,
                    (sum, t) => sum + t.amount,
                  );

                  DateTime firstActivity = current.createdAt;
                  for (final t in [...deposits, ...withdrawals]) {
                    if (t.date.isBefore(firstActivity)) {
                      firstActivity = t.date;
                    }
                  }
                  final now = DateTime.now();
                  final monthsActive = _monthsInclusive(firstActivity, now);
                  final avgPerMonth = monthsActive > 0
                      ? current.currentAmount / monthsActive
                      : 0.0;

                  final remaining = current.remaining;
                  final progress = current.progress.clamp(0.0, 1.0);

                  String estimateText;
                  String estimateSub;
                  if (current.isCompleted) {
                    estimateText = 'Tercapai!';
                    estimateSub = 'Target sudah terpenuhi';
                  } else if (avgPerMonth <= 0) {
                    estimateText = 'Belum ada data';
                    estimateSub =
                        'Lakukan setoran pertama untuk melihat perkiraan';
                  } else {
                    final monthsNeeded = remaining / avgPerMonth;
                    final ceilMonths = monthsNeeded.ceil();
                    final estimated = DateTime(
                      now.year,
                      now.month + ceilMonths,
                      1,
                    );
                    estimateText =
                        '± $ceilMonths bulan (${monthYearId.format(estimated)})';
                    estimateSub =
                        'Rata-rata ${formatRupiah(avgPerMonth)}/bulan';
                  }

                  String? deadlineNote;
                  if (!current.isCompleted &&
                      current.deadline != null &&
                      avgPerMonth > 0) {
                    final monthsToDeadline =
                        (current.deadline!.year * 12 +
                            current.deadline!.month) -
                        (now.year * 12 + now.month) +
                        1;
                    if (monthsToDeadline <= 0) {
                      deadlineNote = 'Deadline sudah lewat';
                    } else {
                      final required = remaining / monthsToDeadline;
                      deadlineNote =
                          'Butuh ${formatRupiah(required)}/bulan agar tercapai sebelum ${dayMonthYearId.format(current.deadline!)}';
                    }
                  }

                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                current.name,
                                style: textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            current.deadline == null
                                ? 'Tanpa deadline'
                                : 'Target ${dayMonthYearId.format(current.deadline!)}',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
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
                          child: SingleChildScrollView(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              20,
                              20,
                              40 + MediaQuery.of(context).padding.bottom,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 10,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      current.isCompleted
                                          ? Colors.green.shade600
                                          : colorScheme.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${formatRupiah(current.currentAmount)} / ${formatRupiah(current.targetAmount)}',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  'Sisa ${formatRupiah(remaining)}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.insights_rounded,
                                            color: colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Perkiraan tercapai',
                                            style: textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: const Color(
                                                    0xFF1E293B,
                                                  ),
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        estimateText,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        estimateSub,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      if (deadlineNote != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          deadlineNote,
                                          style: textTheme.bodySmall?.copyWith(
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _statTile(
                                        context,
                                        'Rata-rata/bulan',
                                        formatRupiah(avgPerMonth),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _statTile(
                                        context,
                                        'Jalan $monthsActive bln',
                                        '${deposits.length}x setor',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _statTile(
                                        context,
                                        'Total setor',
                                        formatRupiah(totalSetor),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _statTile(
                                        context,
                                        'Total tarik',
                                        formatRupiah(totalTarik),
                                      ),
                                    ),
                                  ],
                                ),
                                if (current.note != null &&
                                    current.note!.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    'Catatan',
                                    style: textTheme.labelLarge?.copyWith(
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    current.note!,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _statTile(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }
}
