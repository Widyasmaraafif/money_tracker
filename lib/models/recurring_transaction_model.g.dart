// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringTransactionModelAdapter
    extends TypeAdapter<RecurringTransactionModel> {
  @override
  final int typeId = 1;

  @override
  RecurringTransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringTransactionModel(
      title: fields[0] as String,
      amount: fields[1] as double,
      type: fields[2] as String,
      category: fields[3] as String,
      paymentMethod: fields[4] as String,
      recurrenceType: fields[5] as RecurrenceType,
      startDate: fields[6] as DateTime,
      endDate: fields[7] as DateTime?,
      nextOccurrence: fields[8] as DateTime,
      isActive: fields[9] as bool,
      hasReminder: fields[10] as bool,
      reminderDateTime: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringTransactionModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.paymentMethod)
      ..writeByte(5)
      ..write(obj.recurrenceType)
      ..writeByte(6)
      ..write(obj.startDate)
      ..writeByte(7)
      ..write(obj.endDate)
      ..writeByte(8)
      ..write(obj.nextOccurrence)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.hasReminder)
      ..writeByte(11)
      ..write(obj.reminderDateTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
