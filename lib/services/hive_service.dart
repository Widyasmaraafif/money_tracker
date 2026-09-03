import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import '../models/recurring_transaction_model.dart';

class HiveService {
  final Box<TransactionModel> box = Hive.box<TransactionModel>('transactions');
  final Box<RecurringTransactionModel> recurringBox =
      Hive.box<RecurringTransactionModel>('recurring_transactions');

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

  void add(TransactionModel trx) {
    try {
      box.add(trx);
    } catch (e, stackTrace) {
      debugPrint('HiveService.add error: $e');
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

  void addRecurring(RecurringTransactionModel trx) {
    try {
      recurringBox.add(trx);
    } catch (e, stackTrace) {
      debugPrint('HiveService.addRecurring error: $e');
      debugPrintStack(stackTrace: stackTrace);
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
}
