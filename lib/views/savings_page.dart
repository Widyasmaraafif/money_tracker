import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/saving_cubit.dart';
import '../blocs/transaction_cubit.dart';
import '../models/saving_goal_model.dart';
import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';
import '../widgets/saving_item.dart';
import 'add_saving_page.dart';
import 'saving_detail_page.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  bool _showArchived = false;

  Future<void> _showAmountDialog({
    required String title,
    required String confirmLabel,
    required int goalIndex,
    required SavingGoalModel goal,
    required bool isDeposit,
  }) async {
    final controller = TextEditingController();
    String paymentMethod = 'cash';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                decoration: InputDecoration(
                  hintText: '0',
                  prefixText: 'Rp ',
                  helperText: isDeposit
                      ? null
                      : 'Terkumpul: ${formatRupiah(goal.currentAmount)}',
                ),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'cash',
                    label: Text('Tunai'),
                    icon: Icon(Icons.wallet_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: 'bank',
                    label: Text('Bank'),
                    icon: Icon(Icons.account_balance_rounded, size: 16),
                  ),
                ],
                selected: {paymentMethod},
                onSelectionChanged: (selection) {
                  setDialogState(() {
                    paymentMethod = selection.first;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ),
    );

    if (result != true || !mounted) return;

    final amount = parseAmount(controller.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nominal yang valid'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!isDeposit && amount > goal.currentAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nominal tarik melebihi saldo tabungan'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final savingCubit = context.read<SavingCubit>();
      if (isDeposit) {
        savingCubit.deposit(goalIndex, amount);
      } else {
        savingCubit.withdraw(goalIndex, amount);
      }
      // Record matching transaction so home balance/stats stay in sync.
      context.read<TransactionCubit>().add(
        TransactionModel(
          title: isDeposit
              ? 'Setor ke ${goal.name}'
              : 'Tarik dari ${goal.name}',
          amount: amount,
          type: isDeposit ? 'expense' : 'income',
          date: DateTime.now(),
          category: 'Tabungan',
          paymentMethod: paymentMethod,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDeposit
                  ? '${formatRupiah(amount)} disetor ke ${goal.name}'
                  : '${formatRupiah(amount)} ditarik dari ${goal.name}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ArgumentError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabungan'),
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
            icon: Icon(
              _showArchived
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.white,
            ),
            tooltip: _showArchived ? 'Sembunyikan arsip' : 'Tampilkan arsip',
            onPressed: () {
              setState(() => _showArchived = !_showArchived);
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
          child: Column(
            children: [
              const SizedBox(height: 12),
              BlocBuilder<SavingCubit, List<SavingGoalModel>>(
                builder: (context, allGoals) {
                  final visible = allGoals
                      .where((g) => _showArchived || !g.isArchived)
                      .toList();
                  final total = allGoals.fold<double>(
                    0,
                    (sum, g) => sum + g.currentAmount,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total terkumpul\n${formatRupiah(total)}',
                            style: textTheme.titleMedium?.copyWith(
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
                            '${visible.length} target',
                            style: textTheme.labelLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
                  child: BlocBuilder<SavingCubit, List<SavingGoalModel>>(
                    builder: (context, allGoals) {
                      final goals = allGoals
                          .where((g) => _showArchived || !g.isArchived)
                          .toList();

                      if (goals.isEmpty) {
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
                                'Belum ada tabungan',
                                style: textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Buat target tabungan pertamamu!',
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
                        itemCount: goals.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final goal = goals[index];
                          return SavingItem(
                            goal: goal,
                            onTap: () async {
                              final cubit = context.read<SavingCubit>();
                              final actualIndex = cubit.indexOf(goal);
                              if (actualIndex != -1) {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SavingDetailPage(
                                      goal: goal,
                                      index: actualIndex,
                                    ),
                                  ),
                                );
                              }
                            },
                            onDelete: () => _showDeleteDialog(context, goal),
                            onDeposit: () {
                              final actualIndex = context
                                  .read<SavingCubit>()
                                  .indexOf(goal);
                              if (actualIndex != -1) {
                                _showAmountDialog(
                                  title: 'Setor ke ${goal.name}',
                                  confirmLabel: 'Setor',
                                  goalIndex: actualIndex,
                                  goal: goal,
                                  isDeposit: true,
                                );
                              }
                            },
                            onWithdraw: () {
                              final actualIndex = context
                                  .read<SavingCubit>()
                                  .indexOf(goal);
                              if (actualIndex != -1) {
                                _showAmountDialog(
                                  title: 'Tarik dari ${goal.name}',
                                  confirmLabel: 'Tarik',
                                  goalIndex: actualIndex,
                                  goal: goal,
                                  isDeposit: false,
                                );
                              }
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
            MaterialPageRoute(builder: (context) => const AddSavingPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, SavingGoalModel goal) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Hapus Tabungan?'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${goal.name}"?\nRiwayat transaksi setor/tarik tetap tersimpan.',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              final cubit = context.read<SavingCubit>();
              final actualIndex = cubit.indexOf(goal);
              if (actualIndex != -1) cubit.delete(actualIndex);
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              minimumSize: const Size(0, 44),
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
