import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';

class HiveService {
  final Box<TransactionModel> box = Hive.box<TransactionModel>('transactions');

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
}
