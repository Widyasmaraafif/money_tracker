import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/transaction_cubit.dart';
import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';
import '../utils/wallets.dart';

class AddTransferPage extends StatefulWidget {
  final TransactionModel? transaction;
  final int? index;

  const AddTransferPage({super.key, this.transaction, this.index});

  @override
  State<AddTransferPage> createState() => _AddTransferPageState();
}

class _AddTransferPageState extends State<AddTransferPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  late DateTime _selectedDate;
  late String _from;
  late String _to;

  bool get isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final trx = widget.transaction;
    _amountController = TextEditingController(
      text: trx != null ? formatAmount(trx.amount) : '',
    );
    _noteController = TextEditingController(
      text: trx != null ? _defaultNoteFallback(trx) : '',
    );
    _selectedDate = trx?.date ?? DateTime.now();
    _from = trx?.paymentMethod ?? Wallets.cash;
    _to = trx?.toPaymentMethod ?? Wallets.bank;
    if (_from == _to) {
      _to = _from == Wallets.cash ? Wallets.bank : Wallets.cash;
    }
  }

  String _defaultNoteFallback(TransactionModel trx) {
    // Judul lama transfer selalu diawali "Transfer", anggap itu auto-title.
    if (trx.title.startsWith('Transfer')) return '';
    return trx.title;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  double _sourceBalance(List<TransactionModel> all) {
    final balances = Wallets.balances(all);
    var balance = balances[_from] ?? 0;
    // Saat edit, kembalikan dulu efek transaksi lama agar validasi adil.
    final old = widget.transaction;
    if (isEditing && old != null && old.type == 'transfer') {
      if (old.paymentMethod == _from) balance += old.amount;
      if (old.toPaymentMethod == _from) balance -= old.amount;
    }
    return balance;
  }

  void _save(List<TransactionModel> all) {
    if (!_formKey.currentState!.validate()) return;
    if (_from == _to) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dompet asal dan tujuan harus berbeda'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final amount = parseAmount(_amountController.text);
    final balance = _sourceBalance(all);
    if (amount > balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saldo ${Wallets.label(_from)} tidak cukup (${formatRupiah(balance)})',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final note = _noteController.text.trim();
    final title = note.isEmpty
        ? 'Transfer ${Wallets.label(_from)} → ${Wallets.label(_to)}'
        : note;
    final trx = TransactionModel(
      title: title,
      amount: amount,
      type: 'transfer',
      date: _selectedDate,
      category: 'Transfer',
      paymentMethod: _from,
      toPaymentMethod: _to,
    );
    final cubit = context.read<TransactionCubit>();
    if (isEditing && widget.index != null) {
      cubit.update(widget.index!, trx);
    } else {
      cubit.add(trx);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Transfer' : 'Transfer Dompet'),
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                BlocBuilder<TransactionCubit, List<TransactionModel>>(
                  builder: (context, all) {
                    final balance = _sourceBalance(all);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _walletPicker(
                                    context,
                                    label: 'Dari',
                                    value: _from,
                                    onChanged: (v) => setState(() {
                                      _from = v;
                                      if (_from == _to) {
                                        _to = _from == Wallets.cash
                                            ? Wallets.bank
                                            : Wallets.cash;
                                      }
                                    }),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 28),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.swap_horiz_rounded,
                                    ),
                                    tooltip: 'Tukar',
                                    onPressed: () => setState(() {
                                      final tmp = _from;
                                      _from = _to;
                                      _to = tmp;
                                    }),
                                  ),
                                ),
                                Expanded(
                                  child: _walletPicker(
                                    context,
                                    label: 'Ke',
                                    value: _to,
                                    onChanged: (v) => setState(() {
                                      _to = v;
                                      if (_from == _to) {
                                        _from = _to == Wallets.cash
                                            ? Wallets.bank
                                            : Wallets.cash;
                                      }
                                    }),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Saldo ${Wallets.label(_from)}: ${formatRupiah(balance)}',
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Nominal',
                              style: textTheme.labelLarge?.copyWith(
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _amountController,
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                              decoration: InputDecoration(
                                hintText: '0',
                                prefixText: 'Rp ',
                                prefixStyle: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                CurrencyInputFormatter(),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Nominal tidak boleh kosong';
                                }
                                if (parseAmount(value) <= 0) {
                                  return 'Masukkan nominal yang valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Catatan (opsional)',
                              style: textTheme.labelLarge?.copyWith(
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _noteController,
                              decoration: const InputDecoration(
                                hintText: 'Contoh: Pindah ke bank',
                                prefixIcon: Icon(Icons.edit_note_rounded),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Tanggal',
                              style: textTheme.labelLarge?.copyWith(
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: _selectDate,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 20,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      DateFormat(
                                        'EEEE, dd MMMM yyyy',
                                        'id_ID',
                                      ).format(_selectedDate),
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            ElevatedButton(
                              onPressed: () => _save(all),
                              child: Text(
                                isEditing
                                    ? 'Simpan Perubahan'
                                    : 'Simpan Transfer',
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _walletPicker(
    BuildContext context, {
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelLarge?.copyWith(
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: Wallets.cash,
              label: Text('Tunai'),
              icon: Icon(Icons.wallet_rounded, size: 16),
            ),
            ButtonSegment(
              value: Wallets.bank,
              label: Text('Bank'),
              icon: Icon(Icons.account_balance_rounded, size: 16),
            ),
          ],
          selected: {value},
          onSelectionChanged: (s) {
            if (s.isNotEmpty) onChanged(s.first);
          },
          style: SegmentedButton.styleFrom(
            backgroundColor: const Color(0xFFF8FAFC),
            selectedBackgroundColor: colorScheme.primary,
            selectedForegroundColor: Colors.white,
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }
}
