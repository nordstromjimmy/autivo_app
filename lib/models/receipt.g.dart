// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReceiptAdapter extends TypeAdapter<Receipt> {
  @override
  final int typeId = 3;

  @override
  Receipt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Receipt(
      id: fields[0] as String?,
      userId: fields[1] as String,
      vehicleId: fields[2] as String,
      maintenanceRecordId: fields[3] as String?,
      storagePath: fields[4] as String,
      fileName: fields[5] as String,
      fileSize: fields[6] as int,
      mimeType: fields[7] as String,
      width: fields[8] as int?,
      height: fields[9] as int?,
      description: fields[10] as String?,
      date: fields[11] as DateTime?,
      amount: fields[12] as double?,
      createdAt: fields[13] as DateTime?,
      updatedAt: fields[14] as DateTime?,
      supabaseId: fields[15] as String?,
      needsSync: fields[16] as bool,
      lastSyncedAt: fields[17] as DateTime?,
      localFilePath: fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Receipt obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.vehicleId)
      ..writeByte(3)
      ..write(obj.maintenanceRecordId)
      ..writeByte(4)
      ..write(obj.storagePath)
      ..writeByte(5)
      ..write(obj.fileName)
      ..writeByte(6)
      ..write(obj.fileSize)
      ..writeByte(7)
      ..write(obj.mimeType)
      ..writeByte(8)
      ..write(obj.width)
      ..writeByte(9)
      ..write(obj.height)
      ..writeByte(10)
      ..write(obj.description)
      ..writeByte(11)
      ..write(obj.date)
      ..writeByte(12)
      ..write(obj.amount)
      ..writeByte(13)
      ..write(obj.createdAt)
      ..writeByte(14)
      ..write(obj.updatedAt)
      ..writeByte(15)
      ..write(obj.supabaseId)
      ..writeByte(16)
      ..write(obj.needsSync)
      ..writeByte(17)
      ..write(obj.lastSyncedAt)
      ..writeByte(18)
      ..write(obj.localFilePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
