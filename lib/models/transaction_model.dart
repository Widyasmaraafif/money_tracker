import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 0)
class TransactionModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String type; // income / expense

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String category;

  @HiveField(5)
  String paymentMethod;

  TransactionModel({
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
    required this.paymentMethod,
  });
}
