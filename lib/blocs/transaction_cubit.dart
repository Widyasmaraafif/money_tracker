import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/transaction_model.dart';
import '../services/hive_service.dart';

class TransactionCubit extends Cubit<List<TransactionModel>> {
  final HiveService service;

  TransactionCubit(this.service) : super([]);

  void load() {
    emit(service.getAll());
  }

  void add(TransactionModel trx) {
    service.add(trx);
    load();
  }

  void delete(int index) {
    service.delete(index);
    load();
  }
}
