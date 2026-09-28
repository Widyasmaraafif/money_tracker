import 'package:hive/hive.dart';

part 'saving_goal_model.g.dart';

@HiveType(typeId: 4)
class SavingGoalModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double targetAmount;

  @HiveField(2)
  double currentAmount;

  @HiveField(3)
  DateTime? deadline;

  @HiveField(4)
  String? note;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  bool isArchived;

  SavingGoalModel({
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    this.note,
    DateTime? createdAt,
    this.isArchived = false,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress {
    if (targetAmount <= 0) return 0;
    return currentAmount / targetAmount;
  }

  double get remaining {
    final diff = targetAmount - currentAmount;
    return diff <= 0 ? 0 : diff;
  }

  bool get isCompleted => targetAmount > 0 && currentAmount >= targetAmount;

  void deposit(double amount) {
    if (amount <= 0) throw ArgumentError('Nominal setor harus lebih dari 0');
    currentAmount += amount;
  }

  void withdraw(double amount) {
    if (amount <= 0) throw ArgumentError('Nominal tarik harus lebih dari 0');
    if (amount > currentAmount) {
      throw ArgumentError('Nominal tarik melebihi saldo tabungan');
    }
    currentAmount -= amount;
  }
}
