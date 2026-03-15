import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'receipt.g.dart';

@HiveType(typeId: 3) // Use next available typeId
class Receipt extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String vehicleId;

  @HiveField(3)
  final String? maintenanceRecordId; // Optional - can be standalone

  // File info
  @HiveField(4)
  final String storagePath; // Path in Supabase Storage

  @HiveField(5)
  final String fileName;

  @HiveField(6)
  final int fileSize; // Bytes

  @HiveField(7)
  final String mimeType; // image/jpeg, image/png

  // Image metadata
  @HiveField(8)
  final int? width;

  @HiveField(9)
  final int? height;

  // Optional metadata
  @HiveField(10)
  final String? description;

  @HiveField(11)
  final DateTime? date; // Receipt date

  @HiveField(12)
  final double? amount; // Optional amount from receipt

  // Timestamps
  @HiveField(13)
  final DateTime createdAt;

  @HiveField(14)
  final DateTime updatedAt;

  // Sync metadata
  @HiveField(15)
  String? supabaseId; // UUID from Supabase

  @HiveField(16)
  bool needsSync;

  @HiveField(17)
  DateTime? lastSyncedAt;

  // Local file path (for offline usage before upload)
  @HiveField(18)
  String? localFilePath;

  Receipt({
    String? id,
    required this.userId,
    required this.vehicleId,
    this.maintenanceRecordId,
    required this.storagePath,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    this.width,
    this.height,
    this.description,
    this.date,
    this.amount,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.supabaseId,
    this.needsSync = true,
    this.lastSyncedAt,
    this.localFilePath,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Copy with
  Receipt copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    String? maintenanceRecordId,
    String? storagePath,
    String? fileName,
    int? fileSize,
    String? mimeType,
    int? width,
    int? height,
    String? description,
    DateTime? date,
    double? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? supabaseId,
    bool? needsSync,
    DateTime? lastSyncedAt,
    String? localFilePath,
  }) {
    return Receipt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      maintenanceRecordId: maintenanceRecordId ?? this.maintenanceRecordId,
      storagePath: storagePath ?? this.storagePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      description: description ?? this.description,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      supabaseId: supabaseId ?? this.supabaseId,
      needsSync: needsSync ?? this.needsSync,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }

  // Mark for sync
  void markForSync() {
    needsSync = true;
  }

  // Mark as synced
  void markSynced(String cloudId) {
    supabaseId = cloudId;
    needsSync = false;
    lastSyncedAt = DateTime.now();
  }

  // Check if uploaded to cloud
  bool get isUploaded => supabaseId != null && !needsSync;

  // Get display size (human readable)
  String get displaySize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Get file extension
  String get fileExtension {
    return fileName.split('.').last.toLowerCase();
  }

  // To JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': supabaseId ?? id,
      'user_id': userId,
      'vehicle_id': vehicleId,
      'maintenance_record_id': maintenanceRecordId,
      'storage_path': storagePath,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'width': width,
      'height': height,
      'description': description,
      'date': date?.toIso8601String(),
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // From JSON (from Supabase)
  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      maintenanceRecordId: json['maintenance_record_id'] as String?,
      storagePath: json['storage_path'] as String,
      fileName: json['file_name'] as String,
      fileSize: json['file_size'] as int,
      mimeType: json['mime_type'] as String,
      width: json['width'] as int?,
      height: json['height'] as int?,
      description: json['description'] as String?,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : null,
      amount: json['amount'] != null
          ? (json['amount'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      supabaseId: json['id'] as String,
      needsSync: false, // From cloud = already synced
      lastSyncedAt: DateTime.now(),
    );
  }
}
