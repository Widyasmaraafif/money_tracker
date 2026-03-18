import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/transaction_cubit.dart';
import '../models/transaction_model.dart';

class AddTransactionPage extends StatefulWidget {
  final TransactionModel? transaction;
  final int? index;

  const AddTransactionPage({super.key, this.transaction, this.index});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late String _type;
  late DateTime _selectedDate;
  late String _category;
  late String _paymentMethod;

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
    _selectedDate = widget.transaction?.date ?? DateTime.now();
    _category = widget.transaction?.category ?? 'Lainnya';
    _paymentMethod = widget.transaction?.paymentMethod ?? 'cash';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
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
          widget.transaction != null ? 'Edit Transaksi' : 'Tambah Transaksi',
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
                        items:
                            [
                              'Makanan & Minuman',
                              'Transportasi',
                              'Belanja',
                              'Hiburan',
                              'Gaji',
                              'Tagihan',
                              'Kesehatan',
                              'Pendidikan',
                              'Lainnya',
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
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
                        'Tanggal',
                        style: textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _selectDate(context),
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
                      const SizedBox(height: 48),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final transaction = TransactionModel(
                              title: _titleController.text,
                              amount: double.parse(_amountController.text),
                              type: _type,
                              date: _selectedDate,
                              category: _category,
                              paymentMethod: _paymentMethod,
                            );

                            if (widget.transaction != null &&
                                widget.index != null) {
                              context.read<TransactionCubit>().update(
                                widget.index!,
                                transaction,
                              );
                            } else {
                              context.read<TransactionCubit>().add(transaction);
                            }
                            Navigator.pop(context);
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
