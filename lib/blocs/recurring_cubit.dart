import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/recurring_transaction_model.dart';
import '../services/hive_service.dart';

class RecurringCubit extends Cubit<List<RecurringTransactionModel>> {
  final HiveService service;

  RecurringCubit(this.service) : super([]);

  void load() {
    emit(service.getAllRecurring());
  }

  int add(RecurringTransactionModel trx) {
    final currentLength = state.length;
    service.addRecurring(trx);
    load();
    return currentLength;
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
    
    // Check if we need to deactivate (past end date)
    if (trx.endDate != null && trx.nextOccurrence.isAfter(trx.endDate!)) {
      trx.isActive = false;
    }
    
    // Save using HiveObject's built-in save method (safer)
    trx.save();
    load();
  }

  void toggleActive(int index) {
    final trx = state[index];
    trx.isActive = !trx.isActive;
    trx.save();
    load();
  }
}
