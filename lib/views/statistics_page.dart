import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../utils/categories.dart';
import '../utils/currency_formatter.dart';

class StatisticsPage extends StatefulWidget {
  final List<TransactionModel> transactions;

  const StatisticsPage({super.key, required this.transactions});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  static const _periods = [
    'Bulan Ini',
    'Bulan Lalu',
    '3 Bulan',
    'Tahun Ini',
    'Semua',
    'Custom',
  ];

  String _period = 'Bulan Ini';
  String _type = 'expense'; // expense / income
  DateTimeRange? _customRange;

  DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59);

  /// Rentang aktif. Null = semua data.
  DateTimeRange? _resolveRange() {
    final now = DateTime.now();
    switch (_period) {
      case 'Bulan Ini':
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case 'Bulan Lalu':
        return DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0, 23, 59, 59),
        );
      case '3 Bulan':
        return DateTimeRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case 'Tahun Ini':
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31, 23, 59, 59),
        );
      case 'Custom':
        return _customRange;
      case 'Semua':
      default:
        return null;
    }
  }

  /// Rentang pembanding dengan durasi sama tepat sebelum rentang aktif.
  DateTimeRange? _previousRange(DateTimeRange cur) {
    final days = cur.end.difference(cur.start).inDays + 1;
    final prevEnd = _startOfDay(cur.start).subtract(const Duration(seconds: 1));
    final prevStart = _startOfDay(prevEnd).subtract(Duration(days: days - 1));
    return DateTimeRange(start: prevStart, end: _endOfDay(prevEnd));
  }

  bool _inRange(DateTime d, DateTimeRange range) =>
      !d.isBefore(range.start) && !d.isAfter(range.end);

  double _sum(Iterable<TransactionModel> list) =>
      list.fold(0.0, (s, t) => s + t.amount);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final range = _resolveRange();

    // Transfer tidak dihitung sebagai income/expense.
    final inRange = widget.transactions.where((t) {
      if (t.type == 'transfer') return false;
      if (range == null) return true;
      return _inRange(t.date, range);
    }).toList();

    final incomeTotal = _sum(inRange.where((t) => t.type == 'income'));
    final expenseTotal = _sum(inRange.where((t) => t.type == 'expense'));
    final net = incomeTotal - expenseTotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik'),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _periodChips(colorScheme),
              ),
              if (_period == 'Custom')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _customPickerButton(context, colorScheme, textTheme),
                ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'expense',
                      label: Text('Pengeluaran'),
                      icon: Icon(Icons.arrow_upward_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: 'income',
                      label: Text('Pemasukan'),
                      icon: Icon(Icons.arrow_downward_rounded, size: 16),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (s) {
                    if (s.isNotEmpty) setState(() => _type = s.first);
                  },
                  style: SegmentedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    selectedBackgroundColor: Colors.white,
                    selectedForegroundColor: colorScheme.primary,
                    side: BorderSide.none,
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Column(
                    children: [
                      _summaryCard(
                        context,
                        colorScheme,
                        textTheme,
                        incomeTotal,
                        expenseTotal,
                        net,
                        range,
                      ),
                      const SizedBox(height: 12),
                      _trendCard(context, colorScheme, textTheme),
                      const SizedBox(height: 12),
                      _breakdownCard(
                        context,
                        type: _type,
                        range: range,
                        inRange: inRange,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kartu pie + rincian kategori untuk satu tipe (expense/income).
  Widget _breakdownCard(
    BuildContext context, {
    required String type,
    required DateTimeRange? range,
    required List<TransactionModel> inRange,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final isExpense = type == 'expense';

    final tabList = inRange.where((t) => t.type == type).toList();
    final tabTotal = _sum(tabList);
    final Map<String, double> categoryData = {};
    for (final t in tabList) {
      categoryData[t.category] = (categoryData[t.category] ?? 0) + t.amount;
    }
    final sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Perbandingan vs periode sebelumnya.
    double? deltaPct;
    if (range != null) {
      final prev = _previousRange(range)!;
      final prevTotal = _sum(
        widget.transactions.where(
          (t) => t.type == type && _inRange(t.date, prev),
        ),
      );
      if (prevTotal > 0) {
        deltaPct = (tabTotal - prevTotal) / prevTotal * 100;
      } else if (tabTotal > 0) {
        deltaPct = 100;
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isExpense ? 'Total pengeluaran' : 'Total pemasukan',
                  style: textTheme.titleSmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (deltaPct != null) _deltaChip(deltaPct, isExpense, textTheme),
            ],
          ),
          Text(
            formatRupiah(tabTotal),
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isExpense ? Colors.red.shade700 : Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 16),
          if (tabList.isEmpty)
            SizedBox(
              height: 220,
              child: Center(
                child: Text(
                  isExpense
                      ? 'Belum ada data pengeluaran\npada periode ini'
                      : 'Belum ada data pemasukan\npada periode ini',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 230,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 50,
                  sections: sortedCategories.map((entry) {
                    final category = TransactionCategory.getByName(entry.key);
                    final pct = tabTotal > 0
                        ? (entry.value / tabTotal) * 100
                        : 0;
                    return PieChartSectionData(
                      color: category.color,
                      value: entry.value,
                      title: '${pct.toStringAsFixed(0)}%',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedCategories.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final entry = sortedCategories[index];
                final category = TransactionCategory.getByName(entry.key);
                final pct = tabTotal > 0 ? (entry.value / tabTotal) * 100 : 0;
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: category.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        category.icon,
                        color: category.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.name,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}% dari total',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatRupiahCompact(entry.value),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isExpense
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _periodChips(ColorScheme colorScheme) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _periods.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final p = _periods[i];
          final selected = p == _period;
          return ChoiceChip(
            label: Text(p),
            selected: selected,
            onSelected: (_) async {
              if (p == 'Custom') {
                await _pickCustomRange();
                return;
              }
              setState(() => _period = p);
            },
            selectedColor: Colors.white,
            backgroundColor: selected
                ? Colors.white
                : Colors.black.withOpacity(0.25),
            labelStyle: TextStyle(
              color: selected ? colorScheme.primary : Colors.white,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: selected
                  ? BorderSide.none
                  : BorderSide(color: Colors.white.withOpacity(0.7), width: 1),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      initialDateRange:
          _customRange ??
          DateTimeRange(start: DateTime(now.year, now.month, 1), end: now),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && mounted) {
      setState(() {
        _customRange = DateTimeRange(
          start: _startOfDay(picked.start),
          end: _endOfDay(picked.end),
        );
        _period = 'Custom';
      });
    }
  }

  Widget _customPickerButton(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final label = _customRange == null
        ? 'Pilih rentang tanggal'
        : '${dayMonthYearId.format(_customRange!.start)} – ${dayMonthYearId.format(_customRange!.end)}';
    return InkWell(
      onTap: _pickCustomRange,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    double income,
    double expense,
    double net,
    DateTimeRange? range,
  ) {
    final rangeLabel = range == null
        ? 'Semua waktu'
        : _period == 'Custom'
        ? '${dayMonthYearId.format(range.start)} – ${dayMonthYearId.format(range.end)}'
        : _period;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rangeLabel,
            style: textTheme.labelLarge?.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _glassStat(
                  context,
                  'Pemasukan',
                  formatRupiahCompact(income),
                  Icons.arrow_downward_rounded,
                  Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _glassStat(
                  context,
                  'Pengeluaran',
                  formatRupiahCompact(expense),
                  Icons.arrow_upward_rounded,
                  Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Selisih',
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const Spacer(),
                Text(
                  '${net >= 0 ? '+' : '−'} ${formatRupiahCompact(net.abs())}',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Naik = baik untuk pemasukan, buruk untuk pengeluaran.
  Widget _deltaChip(double pct, bool isExpense, TextTheme textTheme) {
    final up = pct >= 0;
    final good = isExpense ? !up : up;
    final color = good ? Colors.green.shade700 : Colors.red.shade700;
    final bg = good ? Colors.green.shade50 : Colors.red.shade50;
    final arrow = up ? '▲' : '▼';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$arrow ${pct.abs().toStringAsFixed(0)}% vs lalu',
        style: textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _trendCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final now = DateTime.now();
    final months = List.generate(
      6,
      (i) => DateTime(now.year, now.month - (5 - i), 1),
    );
    final incomes = <double>[];
    final expenses = <double>[];
    for (final m in months) {
      final end = DateTime(m.year, m.month + 1, 0, 23, 59, 59);
      double inc = 0, exp = 0;
      for (final t in widget.transactions) {
        if (t.type == 'transfer') continue;
        if (t.date.isBefore(m) || t.date.isAfter(end)) continue;
        if (t.type == 'income') {
          inc += t.amount;
        } else {
          exp += t.amount;
        }
      }
      incomes.add(inc);
      expenses.add(exp);
    }
    final maxVal = [
      ...incomes,
      ...expenses,
    ].fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = maxVal <= 0 ? 100.0 : maxVal * 1.2;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tren 6 bulan',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              _legendDot(Colors.green.shade500, 'Masuk'),
              const SizedBox(width: 12),
              _legendDot(Colors.red.shade400, 'Keluar'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final m = months[group.x.toInt()];
                      final label = monthYearId.format(m);
                      final kind = rodIndex == 0 ? 'Masuk' : 'Keluar';
                      final val = rodIndex == 0
                          ? incomes[group.x.toInt()]
                          : expenses[group.x.toInt()];
                      return BarTooltipItem(
                        '$label\n$kind: ${formatRupiahCompact(val)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (v, _) => Text(
                        formatRupiahCompact(v),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= months.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat(
                              'MMM',
                              'id_ID',
                            ).format(months[i]).replaceAll('.', ''),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(months.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: incomes[i],
                        color: Colors.green.shade500,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                      BarChartRodData(
                        toY: expenses[i],
                        color: Colors.red.shade400,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
