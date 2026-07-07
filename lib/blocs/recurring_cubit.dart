import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/recurring_transaction_model.dart';
import '../services/hive_service.dart';

class RecurringCubit extends Cubit<List<RecurringTransactionModel>> {
  final HiveService service;

  RecurringCubit(this.service) : super([]);

  void load() {
    emit(service.getAllRecurring());
  }

  void add(RecurringTransactionModel trx) {
    service.addRecurring(trx);
    load();
  }

  void delete(int index) {
    service.deleteRecurring(index);
    load();
  }

  void update(int index, RecurringTransactionModel trx) {
    service.updateRecurring(index, trx);
    load();
  }

  void markAsOccurred(int index) {
    final trx = state[index];
    trx.updateNextOccurrence();
    update(index, trx);
  }
}
