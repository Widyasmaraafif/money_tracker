import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/transaction_model.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';

class TransactionCubit extends Cubit<List<TransactionModel>> {
  final HiveService service;

  TransactionCubit(this.service) : super([]);

  void load() {
    emit(service.getAll());
    // Sinkronkan pengingat harian tiap data berubah (ada/tidak catat hari ini).
    NotificationService.refreshDailyLogReminder().ignore();
  }

  void add(TransactionModel trx) {
    service.add(trx);
    load();
  }

  void delete(int index) {
    service.delete(index);
    load();
  }

  /// Kembalikan transaksi yang baru dihapus ke posisi semula (Undo).
  Future<bool> restoreAt(int index, TransactionModel trx) async {
    final restored = await service.restoreAt(index, trx);
    load();
    return restored != null;
  }

  void update(int index, TransactionModel trx) {
    service.update(index, trx);
    load();
  }
}
