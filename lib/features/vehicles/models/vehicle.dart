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

  @HiveField(18)
  int? currentMileage; // Current odometer reading

  // ==================== SYNC METADATA ====================
  // These fields enable cloud sync without breaking offline functionality

  @HiveField(19)
  String? supabaseId; // ID in Supabase database (null if not synced yet)

  @HiveField(20)
  DateTime? lastSyncedAt; // Last successful sync to cloud

  @HiveField(21)
  bool needsSync; // Has local changes that need uploading

  @HiveField(22)
  String? userId; // Supabase user ID who owns this vehicle (null for anonymous)

  @HiveField(23)
  DateTime updatedAt; // Last local update time (for conflict resolution)

  // ==================== NEW: VERIFICATION CONFIDENCE ====================
  @HiveField(24)
  int? verificationConfidence; // 0-100 confidence score from OCR validation

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
    this.currentMileage,
    // Sync fields with sensible defaults
    this.supabaseId,
    this.lastSyncedAt,
    this.needsSync = true, // Default to needing sync (new records)
    this.userId,
    DateTime? updatedAt,
    this.verificationConfidence, // NEW: Confidence score
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Mark this vehicle as needing sync (call after any edit)
  void markForSync() {
    needsSync = true;
    updatedAt = DateTime.now();
  }

  // Mark as successfully synced (call after cloud upload)
  void markSynced(String cloudId) {
    supabaseId = cloudId;
    lastSyncedAt = DateTime.now();
    needsSync = false;
  }

  // Check if this vehicle is synced to cloud
  bool get isSynced => supabaseId != null;

  // Check if user is signed in (has userId)
  bool get hasCloudBackup => userId != null;

  // Getters
  int get daysUntilBesiktning {
    if (nextBesiktningDate == null) {
      return 0;
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

  // UPDATED: Use confidence score for better badge
  String get verificationBadge {
    if (verificationLevel == 'none') return '';

    // For OCR-verified vehicles, use confidence score
    if (verificationLevel == 'self' && verificationConfidence != null) {
      if (verificationConfidence! >= 90) {
        return 'med registreringsbevis';
      }
      return '✓ Ägare';
    }

    // Fallback to old badge system
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

  // PDF-safe verification badge (removes checkmarks)
  String get verificationBadgePdf {
    if (verificationLevel == 'none') return '';

    if (verificationLevel == 'self' && verificationConfidence != null) {
      if (verificationConfidence! >= 90) {
        return 'VERIFIERAD';
      }
      return 'ÄGARE';
    }

    switch (verificationLevel) {
      case 'self':
        return 'ÄGARE';
      case 'sms':
        return 'VERIFIERAD';
      case 'official':
        return 'OFFICIELLT VERIFIERAD';
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

  // Create a copy with updated fields (useful for syncing)
  Vehicle copyWith({
    String? id,
    String? registrationNumber,
    String? make,
    String? model,
    int? year,
    String? fuelType,
    String? engineSize,
    DateTime? nextBesiktningDate,
    DateTime? createdAt,
    String? verificationLevel,
    DateTime? verifiedAt,
    String? verificationProof,
    bool? isCurrentOwner,
    DateTime? ownershipStartDate,
    DateTime? ownershipEndDate,
    String? transferCode,
    String? previousOwnerId,
    bool? receivedViaTransfer,
    int? currentMileage,
    String? supabaseId,
    DateTime? lastSyncedAt,
    bool? needsSync,
    String? userId,
    DateTime? updatedAt,
    int? verificationConfidence,
  }) {
    return Vehicle(
      id: id ?? this.id,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      fuelType: fuelType ?? this.fuelType,
      engineSize: engineSize ?? this.engineSize,
      nextBesiktningDate: nextBesiktningDate ?? this.nextBesiktningDate,
      createdAt: createdAt ?? this.createdAt,
      verificationLevel: verificationLevel ?? this.verificationLevel,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verificationProof: verificationProof ?? this.verificationProof,
      isCurrentOwner: isCurrentOwner ?? this.isCurrentOwner,
      ownershipStartDate: ownershipStartDate ?? this.ownershipStartDate,
      ownershipEndDate: ownershipEndDate ?? this.ownershipEndDate,
      transferCode: transferCode ?? this.transferCode,
      previousOwnerId: previousOwnerId ?? this.previousOwnerId,
      receivedViaTransfer: receivedViaTransfer ?? this.receivedViaTransfer,
      currentMileage: currentMileage ?? this.currentMileage,
      supabaseId: supabaseId ?? this.supabaseId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      needsSync: needsSync ?? this.needsSync,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
      verificationConfidence:
          verificationConfidence ?? this.verificationConfidence, // NEW
    );
  }
}
