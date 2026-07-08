import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/recurring_cubit.dart';
import '../models/recurring_transaction_model.dart';
import '../utils/categories.dart';
import '../services/notification_service.dart';

class AddRecurringTransactionPage extends StatefulWidget {
  final RecurringTransactionModel? transaction;
  final int? index;

  const AddRecurringTransactionPage({super.key, this.transaction, this.index});

  @override
  State<AddRecurringTransactionPage> createState() =>
      _AddRecurringTransactionPageState();
}

class _AddRecurringTransactionPageState
    extends State<AddRecurringTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late String _type;
  late DateTime _startDate;
  DateTime? _endDate;
  late String _category;
  late String _paymentMethod;
  late RecurrenceType _recurrenceType;
  bool _hasReminder = false;
  TimeOfDay? _reminderTime;
  late DateTime _nextOccurrence;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.transaction?.title ?? '',
    );
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toString() ?? '',
    );
    _type = widget.transaction?.type ?? 'expense';
    _startDate = widget.transaction?.startDate ?? DateTime.now();
    _endDate = widget.transaction?.endDate;
    _category = widget.transaction?.category ?? 'Lainnya';
    _paymentMethod = widget.transaction?.paymentMethod ?? 'cash';
    _recurrenceType =
        widget.transaction?.recurrenceType ?? RecurrenceType.monthly;
    _hasReminder = widget.transaction?.hasReminder ?? false;
    _reminderTime = widget.transaction?.reminderTime;
    _nextOccurrence = widget.transaction?.nextOccurrence ?? _startDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.transaction != null
              ? 'Edit Transaksi Rutin'
              : 'Tambah Transaksi Rutin',
        ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            children: [
              const SizedBox(height: kToolbarHeight + 40),
              Container(
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
                      Text(
                        'Jenis Transaksi',
                        style: textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'expense',
                            label: Text('Pengeluaran'),
                            icon: Icon(Icons.remove_circle_outline, size: 18),
                          ),
                          ButtonSegment(
                            value: 'income',
                            label: Text('Pemasukan'),
                            icon: Icon(Icons.add_circle_outline, size: 18),
                          ),
                        ],
                        selected: {_type},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _type = newSelection.first;
                            _category = TransactionCategory.getAll(
                              _type,
                            ).first.name;
                          });
                        },
                        style: SegmentedButton.styleFrom(
                          backgroundColor: const Color(0xFFF8FAFC),
                          selectedBackgroundColor: _type == 'income'
                              ? Colors.green.shade600
                              : Colors.orange.shade700,
                          selectedForegroundColor: Colors.white,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
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
                          prefixIcon: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Rp',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nominal tidak boleh kosong';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Masukkan angka yang valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Keterangan',
                        style: textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Contoh: Beli Kopi',
                          prefixIcon: Icon(Icons.edit_note_rounded),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Keterangan tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Kategori',
                        style: textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: TransactionCategory.getAll(_type).map((
                          TransactionCategory cat,
                        ) {
                          return DropdownMenuItem<String>(
                            value: cat.name,
                            child: Row(
                              children: [
                                Icon(cat.icon, color: cat.color, size: 20),
                                const SizedBox(width: 12),
                                Text(cat.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _category = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Metode',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(
                                      value: 'cash',
                                      label: Text('Tunai'),
                                    ),
                                    ButtonSegment(
                                      value: 'bank',
                                      label: Text('Bank'),
                                    ),
                                  ],
                                  selected: {_paymentMethod},
                                  onSelectionChanged:
                                      (Set<String> newSelection) {
                                        setState(() {
                                          _paymentMethod = newSelection.first;
                                        });
                                      },
                                  style: SegmentedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF8FAFC),
                                    selectedBackgroundColor:
                                        colorScheme.primary,
                                    selectedForegroundColor: Colors.white,
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Perulangan',
                        style: textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<RecurrenceType>(
                        value: _recurrenceType,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: RecurrenceType.values.map((type) {
                          String label = '';
                          switch (type) {
                            case RecurrenceType.daily:
                              label = 'Harian';
                              break;
                            case RecurrenceType.weekly:
                              label = 'Mingguan';
                              break;
                            case RecurrenceType.monthly:
                              label = 'Bulanan';
                              break;
                            case RecurrenceType.yearly:
                              label = 'Tahunan';
                              break;
                          }
                          return DropdownMenuItem<RecurrenceType>(
                            value: type,
                            child: Text(label),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _recurrenceType = newValue;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tanggal Mulai',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: () => _selectDate(context, true),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
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
                                        Expanded(
                                          child: Text(
                                            DateFormat(
                                              'dd MMM yyyy',
                                              'id_ID',
                                            ).format(_startDate),
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(
                                                    0xFF1E293B,
                                                  ),
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tanggal Selesai',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: const Color(0xFF64748B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: () => _selectDate(context, false),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
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
                                        Expanded(
                                          child: Text(
                                            _endDate != null
                                                ? DateFormat(
                                                    'dd MMM yyyy',
                                                    'id_ID',
                                                  ).format(_endDate!)
                                                : 'Pilih Tanggal',
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: _endDate != null
                                                      ? const Color(0xFF1E293B)
                                                      : Colors.grey.shade400,
                                                ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      SwitchListTile(
                        title: Text(
                          'Reminder',
                          style: textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF1E293B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        value: _hasReminder,
                        onChanged: (value) {
                          setState(() {
                            _hasReminder = value;
                            if (_hasReminder && _reminderTime == null) {
                              _reminderTime = TimeOfDay.now();
                            }
                          });
                        },
                        activeColor: colorScheme.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_hasReminder) ...[
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () => _selectTime(context),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 20,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _reminderTime != null
                                        ? _reminderTime!.format(context)
                                        : 'Pilih Waktu',
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 48),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              // Create transaction and use the setter if needed
                              final transaction = RecurringTransactionModel(
                                title: _titleController.text,
                                amount: double.parse(_amountController.text),
                                type: _type,
                                category: _category,
                                paymentMethod: _paymentMethod,
                                recurrenceType: _recurrenceType,
                                startDate: _startDate,
                                endDate: _endDate,
                                nextOccurrence: _nextOccurrence,
                                isActive: widget.transaction?.isActive ?? true,
                                hasReminder: _hasReminder,
                              );
                              // Use the setter to handle conversion from TimeOfDay to DateTime
                              transaction.reminderTime = _reminderTime;

                              if (widget.transaction != null &&
                                  widget.index != null) {
                                context.read<RecurringCubit>().update(
                                  widget.index!,
                                  transaction,
                                );
                                if (_hasReminder) {
                                  await NotificationService.scheduleReminder(
                                    transaction,
                                    widget.index! + 1000,
                                  );
                                } else {
                                  await NotificationService.cancelReminder(
                                    widget.index! + 1000,
                                  );
                                }
                              } else {
                                final index = context
                                    .read<RecurringCubit>()
                                    .add(transaction);
                                if (_hasReminder) {
                                  await NotificationService.scheduleReminder(
                                    transaction,
                                    index + 1000,
                                  );
                                }
                              }
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            } catch (e, stackTrace) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                              debugPrint('Error saving transaction: $e');
                              debugPrintStack(stackTrace: stackTrace);
                            }
                          }
                        },
                        child: Text(
                          widget.transaction != null
                              ? 'Simpan Perubahan'
                              : 'Simpan Transaksi',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
