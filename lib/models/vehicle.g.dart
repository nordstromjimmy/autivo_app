// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VehicleAdapter extends TypeAdapter<Vehicle> {
  @override
  final int typeId = 0;

  @override
  Vehicle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Vehicle(
      id: fields[0] as String,
      registrationNumber: fields[1] as String,
      make: fields[2] as String,
      model: fields[3] as String,
      year: fields[4] as int,
      fuelType: fields[5] as String?,
      engineSize: fields[6] as String?,
      nextBesiktningDate: fields[7] as DateTime,
      createdAt: fields[8] as DateTime?,
      verificationLevel: fields[9] as String,
      verifiedAt: fields[10] as DateTime?,
      verificationProof: fields[11] as String?,
      isCurrentOwner: fields[12] as bool,
      ownershipStartDate: fields[13] as DateTime?,
      ownershipEndDate: fields[14] as DateTime?,
      transferCode: fields[15] as String?,
      previousOwnerId: fields[16] as String?,
      receivedViaTransfer: fields[17] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Vehicle obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.registrationNumber)
      ..writeByte(2)
      ..write(obj.make)
      ..writeByte(3)
      ..write(obj.model)
      ..writeByte(4)
      ..write(obj.year)
      ..writeByte(5)
      ..write(obj.fuelType)
      ..writeByte(6)
      ..write(obj.engineSize)
      ..writeByte(7)
      ..write(obj.nextBesiktningDate)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.verificationLevel)
      ..writeByte(10)
      ..write(obj.verifiedAt)
      ..writeByte(11)
      ..write(obj.verificationProof)
      ..writeByte(12)
      ..write(obj.isCurrentOwner)
      ..writeByte(13)
      ..write(obj.ownershipStartDate)
      ..writeByte(14)
      ..write(obj.ownershipEndDate)
      ..writeByte(15)
      ..write(obj.transferCode)
      ..writeByte(16)
      ..write(obj.previousOwnerId)
      ..writeByte(17)
      ..write(obj.receivedViaTransfer);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
