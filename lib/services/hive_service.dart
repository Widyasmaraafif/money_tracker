import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import '../models/recurring_transaction_model.dart';
import '../models/budget_model.dart';
import '../models/saving_goal_model.dart';

class HiveService {
  Box<TransactionModel> get box => Hive.box<TransactionModel>('transactions');
  Box<RecurringTransactionModel> get recurringBox =>
      Hive.box<RecurringTransactionModel>('recurring_transactions');
  Box<BudgetModel> get budgetBox => Hive.box<BudgetModel>('budgets');
  Box<SavingGoalModel> get savingBox => Hive.box<SavingGoalModel>('savings');

  // Transaction methods
  List<TransactionModel> getAll() {
    try {
      return box.values.toList();
    } catch (e, stackTrace) {
      debugPrint('HiveService.getAll error: $e');
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  Future<void> add(TransactionModel trx) async {
    try {
      await box.add(trx);
    } catch (e, stackTrace) {
      debugPrint('HiveService.add error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> addAll(List<TransactionModel> list) async {
    try {
      await box.addAll(list);
    } catch (e, stackTrace) {
      debugPrint('HiveService.addAll error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void delete(int index) {
    try {
      box.deleteAt(index);
    } catch (e, stackTrace) {
      debugPrint('HiveService.delete error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void update(int index, TransactionModel trx) {
    try {
      box.putAt(index, trx);
    } catch (e, stackTrace) {
      debugPrint('HiveService.update error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // Recurring Transaction methods
  List<RecurringTransactionModel> getAllRecurring() {
    try {
      return recurringBox.values.toList();
    } catch (e, stackTrace) {
      debugPrint('HiveService.getAllRecurring error: $e');
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  Future<int?> addRecurring(RecurringTransactionModel trx) async {
    try {
      return await recurringBox.add(trx);
    } catch (e, stackTrace) {
      debugPrint('HiveService.addRecurring error: $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }

  void deleteRecurring(int index) {
    try {
      recurringBox.deleteAt(index);
    } catch (e, stackTrace) {
      debugPrint('HiveService.deleteRecurring error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void updateRecurring(int index, RecurringTransactionModel trx) {
    try {
      recurringBox.putAt(index, trx);
    } catch (e, stackTrace) {
      debugPrint('HiveService.updateRecurring error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // Budget methods
  List<BudgetModel> getAllBudgets() {
    try {
      return budgetBox.values.toList();
    } catch (e, stackTrace) {
      debugPrint('HiveService.getAllBudgets error: $e');
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  List<BudgetModel> getBudgetsForMonth(int month, int year) {
    return getAllBudgets()
        .where((b) => b.month == month && b.year == year)
        .toList();
  }

  void addBudget(BudgetModel budget) {
    try {
      budgetBox.add(budget);
    } catch (e, stackTrace) {
      debugPrint('HiveService.addBudget error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void deleteBudget(int index) {
    try {
      budgetBox.deleteAt(index);
    } catch (e, stackTrace) {
      debugPrint('HiveService.deleteBudget error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void updateBudget(int index, BudgetModel budget) {
    try {
      budgetBox.putAt(index, budget);
    } catch (e, stackTrace) {
      debugPrint('HiveService.updateBudget error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  // Saving goal methods
  List<SavingGoalModel> getAllSavings() {
    try {
      return savingBox.values.toList();
    } catch (e, stackTrace) {
      debugPrint('HiveService.getAllSavings error: $e');
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  void addSaving(SavingGoalModel goal) {
    try {
      savingBox.add(goal);
    } catch (e, stackTrace) {
      debugPrint('HiveService.addSaving error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void deleteSaving(int index) {
    try {
      savingBox.deleteAt(index);
    } catch (e, stackTrace) {
      debugPrint('HiveService.deleteSaving error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void updateSaving(int index, SavingGoalModel goal) {
    try {
      savingBox.putAt(index, goal);
    } catch (e, stackTrace) {
      debugPrint('HiveService.updateSaving error: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
