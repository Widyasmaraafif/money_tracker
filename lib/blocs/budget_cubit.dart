import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/budget_model.dart';
import '../services/hive_service.dart';

class BudgetCubit extends Cubit<List<BudgetModel>> {
  final HiveService service;

  BudgetCubit(this.service) : super([]);

  void load() {
    emit(service.getAllBudgets());
  }

  void loadForMonth(int month, int year) {
    emit(service.getBudgetsForMonth(month, year));
  }

  void add(BudgetModel budget) {
    service.addBudget(budget);
    loadForMonth(budget.month, budget.year);
  }

  void delete(int index) {
    // index refers to position inside the full budgets box.
    // Callers should resolve the real box index before calling.
    service.deleteBudget(index);
    load();
  }

  void update(int index, BudgetModel budget) {
    service.updateBudget(index, budget);
    loadForMonth(budget.month, budget.year);
  }

  /// Resolve the real Hive box index for a budget instance.
  int indexOf(BudgetModel budget) {
    final all = service.getAllBudgets();
    return all.indexOf(budget);
  }
}
