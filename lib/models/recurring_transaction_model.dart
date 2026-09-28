import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'recurring_transaction_model.g.dart';

enum RecurrenceType { daily, weekly, monthly, yearly }

class RecurrenceTypeAdapter extends TypeAdapter<RecurrenceType> {
  @override
  final int typeId = 3;

  @override
  RecurrenceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RecurrenceType.daily;
      case 1:
        return RecurrenceType.weekly;
      case 2:
        return RecurrenceType.monthly;
      case 3:
        return RecurrenceType.yearly;
      default:
        return RecurrenceType.monthly;
    }
  }

  @override
  void write(BinaryWriter writer, RecurrenceType obj) {
    switch (obj) {
      case RecurrenceType.daily:
        writer.writeByte(0);
        break;
      case RecurrenceType.weekly:
        writer.writeByte(1);
        break;
      case RecurrenceType.monthly:
        writer.writeByte(2);
        break;
      case RecurrenceType.yearly:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

@HiveType(typeId: 1)
class RecurringTransactionModel extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  String type; // income / expense

  @HiveField(3)
  String category;

  @HiveField(4)
  String paymentMethod;

  @HiveField(5)
  RecurrenceType recurrenceType;

  @HiveField(6)
  DateTime startDate;

  @HiveField(7)
  DateTime? endDate;

  @HiveField(8)
  DateTime nextOccurrence;

  @HiveField(9)
  bool isActive;

  @HiveField(10)
  bool hasReminder;

  @HiveField(11)
  DateTime? reminderDateTime;

  RecurringTransactionModel({
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.paymentMethod,
    required this.recurrenceType,
    required this.startDate,
    this.endDate,
    required this.nextOccurrence,
    this.isActive = true,
    this.hasReminder = false,
    this.reminderDateTime,
  });

  // Helper getter and setter for TimeOfDay
  TimeOfDay? get reminderTime {
    if (reminderDateTime == null) return null;
    return TimeOfDay(
      hour: reminderDateTime!.hour,
      minute: reminderDateTime!.minute,
    );
  }

  set reminderTime(TimeOfDay? time) {
    if (time == null) {
      reminderDateTime = null;
    } else {
      // Create a DateTime with only hour and minute from TimeOfDay
      final now = DateTime.now();
      reminderDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );
    }
  }

  void updateNextOccurrence() {
    switch (recurrenceType) {
      case RecurrenceType.daily:
        nextOccurrence = nextOccurrence.add(const Duration(days: 1));
        break;
      case RecurrenceType.weekly:
        nextOccurrence = nextOccurrence.add(const Duration(days: 7));
        break;
      case RecurrenceType.monthly:
        // Handle month increment with day overflow
        final nextMonth = DateTime(
          nextOccurrence.year,
          nextOccurrence.month + 2,
          0,
        );
        final day = nextOccurrence.day > nextMonth.day
            ? nextMonth.day
            : nextOccurrence.day;
        nextOccurrence = DateTime(
          nextOccurrence.year,
          nextOccurrence.month + 1,
          day,
        );
        break;
      case RecurrenceType.yearly:
        // Handle leap year for February 29
        final nextYear = nextOccurrence.year + 1;
        final isLeap =
            (nextYear % 4 == 0 && nextYear % 100 != 0) || (nextYear % 400 == 0);
        final day =
            (nextOccurrence.month == 2 && nextOccurrence.day == 29 && !isLeap)
            ? 28
            : nextOccurrence.day;
        nextOccurrence = DateTime(nextYear, nextOccurrence.month, day);
        break;
    }
  }
}
