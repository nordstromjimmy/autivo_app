import 'package:hive/hive.dart';
import 'package:mina_fordon/core/services/notifications/notification_scheduler.dart';
import '../../../core/services/notifications/notification_preferences.dart';
import '../../../core/services/notifications/notification_service.dart';
import '../../../core/services/notifications/notification_types.dart';
import '../../maintenance/repositories/maintenance_repository.dart';
import '../../receipts/repositories/receipt_repository.dart';
import '../models/vehicle.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/services/sync/sync_service.dart';

class VehicleRepository {
  static const String boxName = 'vehicles';
  final SyncService _syncService = SyncService();
  final NotificationScheduler? _notificationScheduler;
  final Function(String message)? _onNotificationEnabled;

  VehicleRepository({
    NotificationScheduler? notificationScheduler,
    Function(String message)? onNotificationEnabled,
  }) : _notificationScheduler = notificationScheduler,
       _onNotificationEnabled = onNotificationEnabled;

  // Get Hive box
  Box<Vehicle> get _box => Hive.box<Vehicle>(boxName);

  // ==================== LOCAL OPERATIONS ====================

  /// Get all vehicles (from local storage)
  List<Vehicle> getAll() {
    return _box.values.toList();
  }

  /// Get vehicle by ID
  Vehicle? getById(String id) {
    try {
      return _box.values.firstWhere((v) => v.id == id);
    } catch (e) {
      return null;
    }
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
    // Get old vehicle to compare inspection date
    final oldVehicle = getById(vehicle.id);
    final oldInspectionDate = oldVehicle?.nextBesiktningDate;
    final newInspectionDate = vehicle.nextBesiktningDate;

    // Mark for sync
    vehicle.markForSync();

    // Update in Hive
    await _box.put(vehicle.id, vehicle);

    // Try to sync to cloud
    if (SupabaseConfig.isSignedIn) {
      await _trySyncVehicle(vehicle);
    }

    // Only handle notifications if inspection date CHANGED
    if (_notificationScheduler != null) {
      // Check if inspection date changed
      final dateChanged = oldInspectionDate != newInspectionDate;

      if (dateChanged) {
        // Date changed - handle scheduling/canceling
        if (newInspectionDate != null) {
          // New date added or date updated - request permissions and schedule
          final permissionGranted = await _ensureNotificationPermissions();
          if (permissionGranted) {
            await _scheduleNotifications(vehicle);
          }
        } else {
          // Date removed - cancel notification
          await _notificationScheduler.cancelInspectionReminder(vehicle.id);
        }
      }
      // If date didn't change - do NOTHING (already scheduled from before)
    }
  }

  /// Delete vehicle and ALL related data (cascade delete)
  Future<bool> delete(String vehicleId) async {
    final vehicle = getById(vehicleId);
    if (vehicle == null) return false;

    // Block if synced and offline
    if (vehicle.supabaseId != null && !SupabaseConfig.isSignedIn) {
      return false;
    }

    try {
      // Step 1: Cancel notifications
      if (_notificationScheduler != null) {
        await _notificationScheduler.cancelInspectionReminder(vehicleId);
      }

      // Step 2: Delete all receipts (includes images from storage)
      final receiptRepo = ReceiptRepository();
      await receiptRepo.deleteByVehicleId(vehicleId);

      // Step 3: Delete all maintenance records
      final maintenanceRepo = MaintenanceRepository();
      await maintenanceRepo.deleteByVehicleId(vehicleId);

      // Step 4: Delete vehicle from cloud
      if (SupabaseConfig.isSignedIn && vehicle.supabaseId != null) {
        await _syncService.deleteVehicle(vehicleId);
      }

      // Step 5: Delete vehicle from local storage
      await _box.delete(vehicleId);

      return true;
    } catch (e, stackTrace) {
      print('❌ Error during cascade delete: $e');
      print('Stack trace: $stackTrace');
      return false;
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

  /// Pull vehicles from cloud and sync with local
  Future<void> pullFromCloud() async {
    if (!SupabaseConfig.isSignedIn) return;

    try {
      final cloudVehicles = await _syncService.downloadVehicles();

      // Get cloud vehicle IDs
      final cloudVehicleIds = cloudVehicles
          .map((data) => data['id'] as String)
          .toSet();

      // Get local vehicle IDs
      final localVehicleIds = _box.keys.toSet();

      // STEP 1: Remove local vehicles not in cloud
      // BUT preserve vehicles that need to be uploaded (needsSync: true)
      for (final localId in localVehicleIds) {
        if (!cloudVehicleIds.contains(localId)) {
          final localVehicle = _box.get(localId);

          // Don't delete if it needs to be uploaded!
          if (localVehicle != null && localVehicle.needsSync) {
            continue; // Skip deletion
          }

          // Vehicle was deleted from cloud (or other device) - remove it
          await _box.delete(localId);
        }
      }

      // STEP 2: Add or merge vehicles from cloud
      for (final data in cloudVehicles) {
        final cloudVehicle = _vehicleFromMap(data);
        final localVehicle = _box.get(cloudVehicle.id);

        if (localVehicle == null) {
          await _box.put(cloudVehicle.id, cloudVehicle);
        } else {
          final merged = _mergeVehicles(localVehicle, cloudVehicle);
          await _box.put(merged.id, merged);
        }
      }
    } catch (e) {
      print('Failed to pull from cloud: $e');
      rethrow;
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
    if (local.needsSync && local.updatedAt.isAfter(cloud.updatedAt)) {
      return local.copyWith(supabaseId: cloud.supabaseId, needsSync: true);
    }

    return cloud.copyWith(needsSync: false);
  }

  /// Ensure notification permissions are granted
  Future<bool> _ensureNotificationPermissions() async {
    final service = NotificationService();
    await service.initialize();

    final granted = await service.requestPermissions();

    if (granted) {
      final preferences = NotificationPreferences();
      await preferences.setEnabled(NotificationType.inspectionReminder, true);

      _onNotificationEnabled?.call('Besiktningspåminnelser aktiverade!');

      return true;
    } else {
      return false;
    }
  }

  /// Schedule notifications if scheduler is available
  Future<void> _scheduleNotifications(Vehicle vehicle) async {
    if (_notificationScheduler == null) return;

    // Simplified - permission already checked in update()
    if (vehicle.nextBesiktningDate == null) return;

    // Schedule inspection reminder
    await _notificationScheduler.scheduleInspectionReminder(
      vehicleId: vehicle.id,
      vehicleRegNumber: vehicle.registrationNumber,
      inspectionDate: vehicle.nextBesiktningDate!,
    );
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
      insuranceCompany: data['insurance_company'] as String?,
      insuranceType: data['insurance_type'] as String?,
      insuranceCostPerYear: data['insurance_cost_per_year'] != null
          ? (data['insurance_cost_per_year'] as num).toDouble()
          : null,
      insuranceRenewalDate: data['insurance_renewal_date'] != null
          ? DateTime.parse(data['insurance_renewal_date'] as String)
          : null,
      insurancePolicyNumber: data['insurance_policy_number'] as String?,
    );
  }

  Future<void> clearInsurance(Vehicle vehicle) async {
    final clearedVehicle = Vehicle(
      id: vehicle.id,
      userId: vehicle.userId,
      registrationNumber: vehicle.registrationNumber,
      make: vehicle.make,
      model: vehicle.model,
      year: vehicle.year,
      fuelType: vehicle.fuelType,
      engineSize: vehicle.engineSize,
      currentMileage: vehicle.currentMileage,
      ownershipStartDate: vehicle.ownershipStartDate,
      nextBesiktningDate: vehicle.nextBesiktningDate,
      verificationLevel: vehicle.verificationLevel,
      verifiedAt: vehicle.verifiedAt,
      verificationProof: vehicle.verificationProof,
      verificationConfidence: vehicle.verificationConfidence,
      createdAt: vehicle.createdAt,
      updatedAt: DateTime.now(),
      needsSync: true,
      supabaseId: vehicle.supabaseId,
      lastSyncedAt: vehicle.lastSyncedAt,
      insuranceCompany: null,
      insuranceType: null,
      insuranceCostPerYear: null,
      insuranceRenewalDate: null,
      insurancePolicyNumber: null,
    );

    await update(clearedVehicle);
  }
}
