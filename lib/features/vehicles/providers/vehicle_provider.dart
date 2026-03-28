import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';
import '../repositories/vehicle_repository.dart';
import '../../maintenance/providers/maintenance_provider.dart';
import '../../receipts/providers/receipt_provider.dart'; // ✅ Add this import
import '../../../core/services/notifications/notification_scheduler.dart';

// Provider for the vehicle repository
final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final notificationScheduler = ref.watch(notificationSchedulerProvider);
  return VehicleRepository(notificationScheduler: notificationScheduler);
});

// Provider for vehicles list (read-only)
final vehiclesProvider = Provider<List<Vehicle>>((ref) {
  // Watch the notifier so this updates when vehicles change
  return ref.watch(vehiclesNotifierProvider);
});

// NotifierProvider for VehiclesNotifier
final vehiclesNotifierProvider =
    NotifierProvider<VehiclesNotifier, List<Vehicle>>(VehiclesNotifier.new);

class VehiclesNotifier extends Notifier<List<Vehicle>> {
  late VehicleRepository _repository;

  @override
  List<Vehicle> build() {
    _repository = ref.read(vehicleRepositoryProvider);
    return _repository.getAll();
  }

  /// Add a new vehicle
  Future<void> addVehicle(Vehicle vehicle) async {
    await _repository.add(vehicle);
    state = _repository.getAll();
    ref.invalidate(pendingSyncCountProvider);
  }

  /// Update existing vehicle
  Future<void> updateVehicle(Vehicle vehicle) async {
    await _repository.update(vehicle);
    state = _repository.getAll();
    ref.invalidate(pendingSyncCountProvider);
  }

  /// Delete vehicle
  Future<bool> deleteVehicle(String vehicleId) async {
    final deleted = await _repository.delete(vehicleId);
    if (deleted) {
      state = _repository.getAll();
      ref.invalidate(pendingSyncCountProvider);
    }
    return deleted;
  }

  /// Refresh vehicles from local storage
  void refresh() {
    state = _repository.getAll();
    ref.invalidate(pendingSyncCountProvider);
  }

  /// Get count of vehicles needing sync
  int get pendingSyncCount => _repository.getPendingSyncCount();

  /// Assign user ID to all vehicles (for migration when user signs in)
  Future<void> assignUserToAllVehicles(String userId) async {
    await _repository.assignUserToAllVehicles(userId);
    state = _repository.getAll();
  }
}

// ==================== AGGREGATE SYNC STATUS PROVIDERS ====================

/// Check if a vehicle OR any of its related data needs sync
final vehicleNeedsSyncProvider = Provider.family<bool, String>((
  ref,
  vehicleId,
) {
  // Handle case where vehicle is deleted
  final vehicles = ref.watch(vehiclesProvider);
  final vehicle = vehicles.where((v) => v.id == vehicleId).firstOrNull;

  // If vehicle doesn't exist, return false (no sync needed)
  if (vehicle == null) return false;

  if (vehicle.needsSync) return true;

  // Check maintenance records using family provider
  final maintenanceRecords = ref.watch(maintenanceProvider(vehicleId));
  if (maintenanceRecords.any((r) => r.needsSync)) return true;

  // Check receipts using family provider
  final receipts = ref.watch(receiptsForVehicleProvider(vehicleId));
  if (receipts.any((r) => r.needsSync)) return true;

  // Nothing needs sync
  return false;
});

/// Get aggregate sync status for a vehicle (vehicle + maintenance + receipts)
final vehicleAggregateSyncStatusProvider =
    Provider.family<VehicleAggregateSync, String>((ref, vehicleId) {
      // Handle case where vehicle is deleted
      final vehicles = ref.watch(vehiclesProvider);
      final vehicle = vehicles.where((v) => v.id == vehicleId).firstOrNull;

      // If vehicle doesn't exist, return default "not found" state
      if (vehicle == null) {
        return VehicleAggregateSync(
          isSynced: false,
          needsSync: false,
          hasCloudBackup: false,
        );
      }

      final needsSync = ref.watch(vehicleNeedsSyncProvider(vehicleId));

      return VehicleAggregateSync(
        isSynced: vehicle.isSynced && !needsSync,
        needsSync: needsSync,
        hasCloudBackup: vehicle.hasCloudBackup,
      );
    });

// ==================== AGGREGATE SYNC STATUS CLASS ====================

/// Simple class to hold aggregate sync status
class VehicleAggregateSync {
  final bool isSynced;
  final bool needsSync;
  final bool hasCloudBackup;

  const VehicleAggregateSync({
    required this.isSynced,
    required this.needsSync,
    required this.hasCloudBackup,
  });
}
