// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saving_goal_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavingGoalModelAdapter extends TypeAdapter<SavingGoalModel> {
  @override
  final int typeId = 4;

  @override
  SavingGoalModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingGoalModel(
      name: fields[0] as String,
      targetAmount: fields[1] as double,
      currentAmount: (fields[2] as num?)?.toDouble() ?? 0,
      deadline: fields[3] as DateTime?,
      note: fields[4] as String?,
      createdAt: fields[5] as DateTime?,
      isArchived: fields[6] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, SavingGoalModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.targetAmount)
      ..writeByte(2)
      ..write(obj.currentAmount)
      ..writeByte(3)
      ..write(obj.deadline)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.isArchived);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingGoalModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
