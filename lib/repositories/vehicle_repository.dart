import 'package:hive/hive.dart';
import '../models/vehicle.dart';
import '../services/supabase_config.dart';
import '../services/sync_service.dart';

class VehicleRepository {
  static const String boxName = 'vehicles';
  final SyncService _syncService = SyncService();

  // Get Hive box
  Box<Vehicle> get _box => Hive.box<Vehicle>(boxName);

  // ==================== LOCAL OPERATIONS ====================

  /// Get all vehicles (from local storage)
  List<Vehicle> getAll() {
    return _box.values.toList();
  }

  /// Get vehicle by ID
  Vehicle? getById(String id) {
    return _box.values.firstWhere(
      (v) => v.id == id,
      orElse: () => throw Exception('Vehicle not found'),
    );
  }

  /// Add a new vehicle
  Future<void> add(Vehicle vehicle) async {
    // Set userId if user is signed in
    if (SupabaseConfig.isSignedIn) {
      vehicle = vehicle.copyWith(
        userId: SupabaseConfig.currentUserId,
        needsSync: true,
      );
    }

    // Save to Hive first (local-first)
    await _box.put(vehicle.id, vehicle);

    // Try to sync to cloud if online and signed in
    if (SupabaseConfig.isSignedIn) {
      await _trySyncVehicle(vehicle);
    }
  }

  /// Update existing vehicle
  Future<void> update(Vehicle vehicle) async {
    // Mark for sync
    vehicle.markForSync();

    // Update in Hive
    await _box.put(vehicle.id, vehicle);

    // Try to sync to cloud
    if (SupabaseConfig.isSignedIn) {
      await _trySyncVehicle(vehicle);
    }
  }

  /// Delete vehicle
  Future<void> delete(String vehicleId) async {
    final vehicle = getById(vehicleId);
    if (vehicle == null) return;

    // Delete from Hive first
    await _box.delete(vehicleId);

    // Delete from cloud if synced
    if (vehicle.supabaseId != null && SupabaseConfig.isSignedIn) {
      await _syncService.deleteVehicle(vehicleId);
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Sync a single vehicle to cloud
  Future<bool> _trySyncVehicle(Vehicle vehicle) async {
    try {
      final cloudId = await _syncService.uploadVehicle(vehicle);

      if (cloudId != null) {
        // Mark as synced
        vehicle.markSynced(cloudId);
        await _box.put(vehicle.id, vehicle);
        return true;
      }
      return false;
    } catch (e) {
      print('Failed to sync vehicle ${vehicle.id}: $e');
      return false;
    }
  }

  /// Sync all pending vehicles to cloud
  Future<int> syncPending() async {
    if (!SupabaseConfig.isSignedIn) return 0;

    final pendingVehicles = _box.values.where((v) => v.needsSync).toList();
    int syncedCount = 0;

    for (final vehicle in pendingVehicles) {
      if (await _trySyncVehicle(vehicle)) {
        syncedCount++;
      }
    }

    return syncedCount;
  }

  /// Pull vehicles from cloud and merge with local
  Future<void> pullFromCloud() async {
    if (!SupabaseConfig.isSignedIn) return;

    try {
      final cloudVehicles = await _syncService.downloadVehicles();

      for (final data in cloudVehicles) {
        final cloudVehicle = _vehicleFromMap(data);
        final localVehicle = _box.get(cloudVehicle.id);

        if (localVehicle == null) {
          // New vehicle from cloud - add it
          await _box.put(cloudVehicle.id, cloudVehicle);
        } else {
          // Vehicle exists locally - merge
          final merged = _mergeVehicles(localVehicle, cloudVehicle);
          await _box.put(merged.id, merged);
        }
      }
    } catch (e) {
      print('Failed to pull vehicles from cloud: $e');
    }
  }

  /// Assign userId to all local vehicles (for migration)
  Future<void> assignUserToAllVehicles(String userId) async {
    final vehicles = _box.values.toList();

    for (final vehicle in vehicles) {
      final updated = vehicle.copyWith(userId: userId, needsSync: true);
      await _box.put(vehicle.id, updated);
    }
  }

  /// Get count of vehicles pending sync
  int getPendingSyncCount() {
    return _box.values.where((v) => v.needsSync).length;
  }

  // ==================== HELPERS ====================

  /// Merge local and cloud vehicle (conflict resolution)
  /// Last-write-wins strategy
  Vehicle _mergeVehicles(Vehicle local, Vehicle cloud) {
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

  /// Convert Supabase map to Vehicle object
  Vehicle _vehicleFromMap(Map<String, dynamic> data) {
    return Vehicle(
      id: data['id'] as String,
      registrationNumber: data['registration_number'] as String,
      make: data['make'] as String,
      model: data['model'] as String,
      year: data['year'] as int,
      fuelType: data['fuel_type'] as String?,
      engineSize: data['engine_size'] as String?,
      nextBesiktningDate: data['next_besiktning_date'] != null
          ? DateTime.parse(data['next_besiktning_date'] as String)
          : null,
      currentMileage: data['current_mileage'] as int?,
      ownershipStartDate: data['ownership_start_date'] != null
          ? DateTime.parse(data['ownership_start_date'] as String)
          : null,
      verificationLevel: data['verification_level'] as String? ?? 'none',
      verifiedAt: data['verified_at'] != null
          ? DateTime.parse(data['verified_at'] as String)
          : null,
      verificationProof: data['verification_proof'] as String?,
      verificationConfidence: data['verification_confidence'] as int?,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
      supabaseId: data['id'] as String,
      userId: data['user_id'] as String,
      needsSync: false, // Just pulled from cloud
      lastSyncedAt: DateTime.now(),
    );
  }
}
