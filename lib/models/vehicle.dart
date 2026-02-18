import 'package:hive/hive.dart';

part 'vehicle.g.dart';

@HiveType(typeId: 0)
class Vehicle extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String registrationNumber;

  @HiveField(2)
  String make;

  @HiveField(3)
  String model;

  @HiveField(4)
  int year;

  @HiveField(5)
  String? fuelType;

  @HiveField(6)
  String? engineSize;

  @HiveField(7)
  DateTime? nextBesiktningDate;

  @HiveField(8)
  DateTime createdAt;

  // Ownership verification fields
  @HiveField(9)
  String verificationLevel; // 'none', 'self', 'sms', 'official'

  @HiveField(10)
  DateTime? verifiedAt;

  @HiveField(11)
  String? verificationProof; // Path to uploaded document or SMS confirmation

  @HiveField(12)
  bool isCurrentOwner; // User claims current ownership

  @HiveField(13)
  DateTime? ownershipStartDate; // When they got the car

  @HiveField(14)
  DateTime? ownershipEndDate; // When they sold it (null if still owner)

  // History transfer
  @HiveField(15)
  String? transferCode; // Code to give to new owner

  @HiveField(16)
  String? previousOwnerId; // Link to previous owner's history

  @HiveField(17)
  bool receivedViaTransfer; // Was this transferred from another user?

  Vehicle({
    required this.id,
    required this.registrationNumber,
    required this.make,
    required this.model,
    required this.year,
    this.fuelType,
    this.engineSize,
    this.nextBesiktningDate,
    DateTime? createdAt,
    this.verificationLevel = 'none',
    this.verifiedAt,
    this.verificationProof,
    this.isCurrentOwner = true,
    this.ownershipStartDate,
    this.ownershipEndDate,
    this.transferCode,
    this.previousOwnerId,
    this.receivedViaTransfer = false,
  }) : createdAt = createdAt ?? DateTime.now();

  // Getters
  int get daysUntilBesiktning {
    if (nextBesiktningDate == null) {
      return 0; // or return a large number like 999
    }
    return nextBesiktningDate!.difference(DateTime.now()).inDays;
  }

  bool get isBesiktningUrgent {
    if (nextBesiktningDate == null) return false;
    return daysUntilBesiktning <= 30;
  }

  bool get isBesiktningOverdue {
    if (nextBesiktningDate == null) return false;
    return daysUntilBesiktning < 0;
  }

  String get urgencyLevel {
    if (nextBesiktningDate == null) return 'none';
    if (daysUntilBesiktning < 0) return 'overdue';
    if (daysUntilBesiktning <= 7) return 'critical';
    if (daysUntilBesiktning <= 30) return 'warning';
    return 'ok';
  }

  bool get isVerified => verificationLevel != 'none';

  String get verificationBadge {
    switch (verificationLevel) {
      case 'self':
        return '✓ Ägare';
      case 'sms':
        return '✓ Verifierad';
      case 'official':
        return '✓ Officiellt Verifierad';
      default:
        return '';
    }
  }

  String get ownershipStatus {
    if (isCurrentOwner) {
      return 'Nuvarande ägare';
    } else if (ownershipEndDate != null) {
      return 'Tidigare ägare (till ${_formatDate(ownershipEndDate!)})';
    } else {
      return 'Tidigare ägare';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }
}
