import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';
import '../models/recurring_transaction_model.dart';

class HiveService {
  final Box<TransactionModel> box = Hive.box<TransactionModel>('transactions');
  final Box<RecurringTransactionModel> recurringBox =
      Hive.box<RecurringTransactionModel>('recurring_transactions');

  // Transaction methods
  List<TransactionModel> getAll() => box.values.toList();

  void add(TransactionModel trx) {
    box.add(trx);
  }

  void delete(int index) {
    box.deleteAt(index);
  }

  void update(int index, TransactionModel trx) {
    box.putAt(index, trx);
  }

  // Recurring Transaction methods
  List<RecurringTransactionModel> getAllRecurring() =>
      recurringBox.values.toList();

  void addRecurring(RecurringTransactionModel trx) {
    recurringBox.add(trx);
  }

  void deleteRecurring(int index) {
    recurringBox.deleteAt(index);
  }

  void updateRecurring(int index, RecurringTransactionModel trx) {
    recurringBox.putAt(index, trx);
  }
}
