// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChecklistStateAdapter extends TypeAdapter<ChecklistState> {
  @override
  final int typeId = 4;

  @override
  ChecklistState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChecklistState(
      vehicleId: fields[0] as String,
      checkedItems: (fields[1] as Map).cast<String, bool>(),
      lastUpdated: fields[2] as DateTime?,
      lastCompleted: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ChecklistState obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.vehicleId)
      ..writeByte(1)
      ..write(obj.checkedItems)
      ..writeByte(2)
      ..write(obj.lastUpdated)
      ..writeByte(3)
      ..write(obj.lastCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
