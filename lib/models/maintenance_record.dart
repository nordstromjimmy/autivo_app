import 'package:hive/hive.dart';

part 'maintenance_record.g.dart';

@HiveType(typeId: 1)
class MaintenanceRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String vehicleId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String type; // 'service', 'parts', 'besiktning', 'other'

  @HiveField(4)
  String description;

  @HiveField(5)
  int? mileage;

  @HiveField(6)
  double? cost;

  @HiveField(7)
  String? location;

  @HiveField(8)
  DateTime createdAt;

  // ==================== SYNC METADATA ====================

  @HiveField(9)
  String? supabaseId; // ID in Supabase database

  @HiveField(10)
  DateTime? lastSyncedAt; // Last successful sync

  @HiveField(11)
  bool needsSync; // Has local changes that need uploading

  @HiveField(12)
  String? userId; // Supabase user ID who owns this record

  @HiveField(13)
  DateTime updatedAt; // Last local update time

  MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.type,
    required this.description,
    this.mileage,
    this.cost,
    this.location,
    DateTime? createdAt,
    // Sync fields with sensible defaults
    this.supabaseId,
    this.lastSyncedAt,
    this.needsSync = true, // Default to needing sync
    this.userId,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Mark this record as needing sync
  void markForSync() {
    needsSync = true;
    updatedAt = DateTime.now();
  }

  // Mark as successfully synced
  void markSynced(String cloudId) {
    supabaseId = cloudId;
    lastSyncedAt = DateTime.now();
    needsSync = false;
  }

  // Check if synced to cloud
  bool get isSynced => supabaseId != null;

  // Check if has cloud backup
  bool get hasCloudBackup => userId != null;

  // Create a copy with updated fields
  MaintenanceRecord copyWith({
    String? id,
    String? vehicleId,
    DateTime? date,
    String? type,
    String? description,
    int? mileage,
    double? cost,
    String? location,
    DateTime? createdAt,
    String? supabaseId,
    DateTime? lastSyncedAt,
    bool? needsSync,
    String? userId,
    DateTime? updatedAt,
  }) {
    return MaintenanceRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      type: type ?? this.type,
      description: description ?? this.description,
      mileage: mileage ?? this.mileage,
      cost: cost ?? this.cost,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      supabaseId: supabaseId ?? this.supabaseId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      needsSync: needsSync ?? this.needsSync,
      userId: userId ?? this.userId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
