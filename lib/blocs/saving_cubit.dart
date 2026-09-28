import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/saving_goal_model.dart';
import '../services/hive_service.dart';

class SavingCubit extends Cubit<List<SavingGoalModel>> {
  final HiveService service;

  SavingCubit(this.service) : super([]);

  void load() {
    emit(service.getAllSavings());
  }

  void add(SavingGoalModel goal) {
    service.addSaving(goal);
    load();
  }

  void delete(int index) {
    // index refers to position inside the full savings box.
    service.deleteSaving(index);
    load();
  }

  void update(int index, SavingGoalModel goal) {
    service.updateSaving(index, goal);
    load();
  }

  /// Resolve the real Hive box index for a goal instance.
  int indexOf(SavingGoalModel goal) {
    final all = service.getAllSavings();
    return all.indexOf(goal);
  }

  /// Add to collected amount. Caller records the matching transaction.
  void deposit(int index, double amount) {
    final goal = service.getAllSavings()[index];
    goal.deposit(amount);
    goal.save();
    load();
  }

  /// Subtract from collected amount. Caller records the matching transaction.
  void withdraw(int index, double amount) {
    final goal = service.getAllSavings()[index];
    goal.withdraw(amount);
    goal.save();
    load();
  }
}
