import 'package:hive/hive.dart';
import 'transaction_model.dart';

part 'budget_model.g.dart';

@HiveType(typeId: 2)
class BudgetModel extends HiveObject {
  @HiveField(0)
  String category;

  @HiveField(1)
  double limit;

  @HiveField(2)
  int month;

  @HiveField(3)
  int year;

  BudgetModel({
    required this.category,
    required this.limit,
    required this.month,
    required this.year,
  });

  /// Total expense spent for this budget's category in its month/year.
  /// Prefer [spentFromTotals] with a pre-aggregated map when rendering lists.
  double spent(List<TransactionModel> transactions) {
    double total = 0;
    for (final trx in transactions) {
      if (trx.type == 'expense' &&
          trx.category == category &&
          trx.date.month == month &&
          trx.date.year == year) {
        total += trx.amount;
      }
    }
    return total;
  }

  /// O(1) lookup from a map built once per frame via [sumExpensesByBudgetKey].
  double spentFromTotals(Map<String, double> totals) =>
      totals[_key(month, year, category)] ?? 0;

  double progressFromSpent(double spentValue) {
    if (limit <= 0) return 0;
    return spentValue / limit;
  }

  static String _key(int month, int year, String category) =>
      '$year-$month|$category';

  /// Aggregate all expenses once: O(T). Key is "year-month|category".
  static Map<String, double> sumExpensesByBudgetKey(
    List<TransactionModel> transactions,
  ) {
    final totals = <String, double>{};
    for (final trx in transactions) {
      if (trx.type != 'expense') continue;
      final key = _key(trx.date.month, trx.date.year, trx.category);
      totals[key] = (totals[key] ?? 0) + trx.amount;
    }
    return totals;
  }

  /// Progress ratio 0.0 - can exceed 1.0 when over budget.
  double progress(List<TransactionModel> transactions) {
    if (limit <= 0) return 0;
    return spent(transactions) / limit;
  }

  bool isOverBudget(List<TransactionModel> transactions) {
    return spent(transactions) > limit;
  }

  bool isNearLimit(List<TransactionModel> transactions) {
    final p = progress(transactions);
    return p >= 0.8 && p <= 1.0;
  }
}
