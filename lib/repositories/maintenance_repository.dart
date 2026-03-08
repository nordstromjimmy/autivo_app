import 'package:hive/hive.dart';
import '../models/maintenance_record.dart';
import '../services/supabase_config.dart';
import '../services/sync_service.dart';
import '../utils/maintenance_deletion_tracker.dart';

class MaintenanceRepository {
  static const String boxName = 'maintenance_records';
  final SyncService _syncService = SyncService();

  // Get Hive box
  Box<MaintenanceRecord> get _box => Hive.box<MaintenanceRecord>(boxName);

  // ==================== LOCAL OPERATIONS ====================

  /// Get all maintenance records for a vehicle
  List<MaintenanceRecord> getByVehicleId(String vehicleId) {
    return _box.values.where((r) => r.vehicleId == vehicleId).toList();
  }

  /// Get record by ID
  MaintenanceRecord? getById(String id) {
    return _box.get(id);
  }

  /// Add a new maintenance record
  Future<void> add(MaintenanceRecord record) async {
    // Set userId if user is signed in
    if (SupabaseConfig.isSignedIn) {
      record = record.copyWith(
        userId: SupabaseConfig.currentUserId,
        needsSync: true,
      );
    }

    // Save to Hive first (local-first)
    await _box.put(record.id, record);

    // Try to sync to cloud if online and signed in
    if (SupabaseConfig.isSignedIn) {
      await _trySyncRecord(record);
    }
  }

  /// Update existing record
  Future<void> update(MaintenanceRecord record) async {
    // Mark for sync
    record.markForSync();

    // Update in Hive
    await _box.put(record.id, record);

    // Try to sync to cloud
    if (SupabaseConfig.isSignedIn) {
      await _trySyncRecord(record);
    }
  }

  /// Delete record
  Future<void> delete(String recordId) async {
    final record = getById(recordId);
    if (record == null) return;

    // Delete from Hive first
    await _box.delete(recordId);

    // Handle cloud deletion
    if (record.supabaseId != null) {
      if (SupabaseConfig.isSignedIn) {
        // Online - delete from cloud immediately
        await _syncService.deleteMaintenanceRecord(recordId);
      } else {
        // Offline - track for later deletion
        await MaintenanceDeletionTracker.trackDeletion(recordId);
      }
    }
  }

  /// Delete all records for a vehicle (when vehicle is deleted)
  Future<void> deleteByVehicleId(String vehicleId) async {
    final records = getByVehicleId(vehicleId);

    for (final record in records) {
      await delete(record.id);
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Sync a single record to cloud
  Future<bool> _trySyncRecord(MaintenanceRecord record) async {
    try {
      final cloudId = await _syncService.uploadMaintenanceRecord(record);

      if (cloudId != null) {
        // Mark as synced
        record.markSynced(cloudId);
        await _box.put(record.id, record);
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Failed to sync maintenance record ${record.id}: $e');
      return false;
    }
  }

  /// Sync all pending records to cloud
  Future<int> syncPending() async {
    if (!SupabaseConfig.isSignedIn) return 0;

    final pendingRecords = _box.values.where((r) => r.needsSync).toList();
    int syncedCount = 0;

    for (final record in pendingRecords) {
      if (await _trySyncRecord(record)) {
        syncedCount++;
      }
    }

    return syncedCount;
  }

  /// Pull records for a vehicle from cloud and merge
  /// Now bidirectional: removes local records not in cloud (unless pending upload)
  Future<void> pullFromCloud(String vehicleId) async {
    if (!SupabaseConfig.isSignedIn) return;

    try {
      final cloudRecords = await _syncService.downloadMaintenanceRecords(
        vehicleId,
      );

      // Get cloud record IDs
      final cloudRecordIds = cloudRecords
          .map((data) => data['id'] as String)
          .toSet();

      // Get local record IDs for this vehicle
      final localRecords = getByVehicleId(vehicleId);
      final localRecordIds = localRecords.map((r) => r.id).toSet();

      // STEP 1: Remove local records not in cloud
      // BUT preserve records that need to be uploaded (needsSync: true)
      for (final localId in localRecordIds) {
        if (!cloudRecordIds.contains(localId)) {
          final localRecord = _box.get(localId);

          // Don't delete if it needs to be uploaded!
          if (localRecord != null && localRecord.needsSync) {
            continue; // Skip deletion - pending upload
          }

          // Record was deleted from cloud (or other device) - remove it
          await _box.delete(localId);
        }
      }

      // STEP 2: Add or merge records from cloud
      for (final data in cloudRecords) {
        final cloudRecord = _recordFromMap(data);
        final localRecord = _box.get(cloudRecord.id);

        if (localRecord == null) {
          // New record from cloud - add it
          await _box.put(cloudRecord.id, cloudRecord);
        } else {
          // Record exists locally - merge
          final merged = _mergeRecords(localRecord, cloudRecord);
          await _box.put(merged.id, merged);
        }
      }
    } catch (e) {
      print('❌ Failed to pull maintenance records from cloud: $e');
      rethrow;
    }
  }

  /// Assign userId to all local records (for migration)
  Future<void> assignUserToAllRecords(String userId) async {
    final records = _box.values.toList();

    for (final record in records) {
      final updated = record.copyWith(userId: userId, needsSync: true);
      await _box.put(record.id, updated);
    }
  }

  /// Get count of records pending sync
  int getPendingSyncCount() {
    return _box.values.where((r) => r.needsSync).length;
  }

  // ==================== HELPERS ====================

  /// Merge local and cloud record (conflict resolution)
  /// Last-write-wins strategy
  MaintenanceRecord _mergeRecords(
    MaintenanceRecord local,
    MaintenanceRecord cloud,
  ) {
    // If local has changes and is newer, keep local
    if (local.needsSync && local.updatedAt.isAfter(cloud.updatedAt)) {
      return local.copyWith(
        supabaseId: cloud.supabaseId, // Preserve cloud ID
        needsSync: true, // Still needs upload
      );
    }

    // Cloud is newer or equal - use cloud version
    return cloud.copyWith(needsSync: false);
  }

  /// Convert Supabase map to MaintenanceRecord object
  MaintenanceRecord _recordFromMap(Map<String, dynamic> data) {
    return MaintenanceRecord(
      id: data['id'] as String,
      vehicleId: data['vehicle_id'] as String,
      date: DateTime.parse(data['date'] as String),
      type: data['type'] as String,
      description: data['description'] as String,
      mileage: data['mileage'] as int?,
      cost: data['cost'] != null ? (data['cost'] as num).toDouble() : null,
      location: data['location'] as String?,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
      supabaseId: data['id'] as String,
      userId: data['user_id'] as String,
      needsSync: false, // Just pulled from cloud
      lastSyncedAt: DateTime.now(),
    );
  }
}
