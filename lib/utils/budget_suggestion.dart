import '../models/transaction_model.dart';

/// Saran budget dari rata-rata pengeluaran 3 bulan sebelum [month]/[year].
class BudgetSuggestion {
  /// Nilai saran yang sudah dibulatkan ke atas.
  final double suggested;

  /// Rata-rata mentah (sebelum dibulatkan).
  final double average;

  /// Total per bulan, urut dari paling lama ke paling baru (3 bulan).
  final List<double> monthlyTotals;

  /// Label bulan, mis. "Jun", "Jul", "Agu".
  final List<String> monthLabels;

  /// Berapa dari 3 bulan itu yang ada pengeluarannya.
  final int monthsWithData;

  const BudgetSuggestion({
    required this.suggested,
    required this.average,
    required this.monthlyTotals,
    required this.monthLabels,
    required this.monthsWithData,
  });
}

const _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// Geser bulan mundur [back] langkah dari [month]/[year].
(int, int) _shiftMonth(int month, int year, int back) {
  var m = month - back;
  var y = year;
  while (m < 1) {
    m += 12;
    y--;
  }
  return (m, y);
}

/// Total expense kategori per bulan target sudah dikurangi [back] bulan.
double _monthTotal(
  List<TransactionModel> transactions,
  String category,
  int month,
  int year,
) {
  var total = 0.0;
  for (final t in transactions) {
    if (t.type == 'expense' &&
        t.category == category &&
        t.date.month == month &&
        t.date.year == year) {
      total += t.amount;
    }
  }
  return total;
}

/// Bulatkan ke atas ke angka "cantik": <100rb -> 10rb, <1jt -> 50rb,
/// selebihnya -> 100rb.
double _roundUpNice(double value) {
  if (value <= 0) return 0;
  final step = value < 100000
      ? 10000
      : value < 1000000
      ? 50000
      : 100000;
  return ((value + step - 1) ~/ step * step).toDouble();
}

/// Saran untuk satu kategori. Null bila 3 bulan sebelumnya kosong semua.
BudgetSuggestion? suggestBudgetForCategory(
  List<TransactionModel> transactions,
  String category, {
  required int month,
  required int year,
}) {
  final totals = <double>[];
  final labels = <String>[];
  for (var back = 3; back >= 1; back--) {
    final (m, y) = _shiftMonth(month, year, back);
    totals.add(_monthTotal(transactions, category, m, y));
    labels.add(_shortMonths[m - 1]);
  }
  final withData = totals.where((v) => v > 0).length;
  if (withData == 0) return null;
  final sum = totals.fold<double>(0, (a, b) => a + b);
  final avg = sum / withData;
  return BudgetSuggestion(
    suggested: _roundUpNice(avg),
    average: avg,
    monthlyTotals: totals,
    monthLabels: labels,
    monthsWithData: withData,
  );
}

/// Saran untuk semua kategori yang punya riwayat tapi belum ada budget
/// di [month]/[year]. Key = nama kategori.
Map<String, BudgetSuggestion> suggestMissingBudgets(
  List<TransactionModel> transactions,
  Set<String> existingCategories, {
  required int month,
  required int year,
}) {
  final result = <String, BudgetSuggestion>{};
  final seen = <String>{};
  for (final t in transactions) {
    if (t.type != 'expense') continue;
    if (!seen.add(t.category)) continue;
    if (existingCategories.contains(t.category)) continue;
    final s = suggestBudgetForCategory(
      transactions,
      t.category,
      month: month,
      year: year,
    );
    if (s != null) result[t.category] = s;
  }
  return result;
}
