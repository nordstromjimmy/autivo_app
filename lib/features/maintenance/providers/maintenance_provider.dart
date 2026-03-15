import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/maintenance_record.dart';
import '../repositories/maintenance_repository.dart';
import '../../receipts/repositories/receipt_repository.dart';
import '../../vehicles/providers/vehicle_provider.dart';

// Provider for the maintenance repository
final maintenanceRepositoryProvider = Provider(
  (ref) => MaintenanceRepository(),
);

// Maintenance notifier (global - manages all records)
final maintenanceNotifierProvider = NotifierProvider<MaintenanceNotifier, void>(
  MaintenanceNotifier.new,
);

class MaintenanceNotifier extends Notifier<void> {
  late MaintenanceRepository _repository;

  @override
  void build() {
    _repository = ref.read(maintenanceRepositoryProvider);
  }

  /// Add a new maintenance record
  Future<void> addRecord(MaintenanceRecord record) async {
    await _repository.add(record);
    ref.invalidate(maintenanceProvider(record.vehicleId));
    ref.invalidate(pendingSyncCountProvider);
  }

  /// Update existing record
  Future<void> updateRecord(MaintenanceRecord record) async {
    await _repository.update(record);
    ref.invalidate(maintenanceProvider(record.vehicleId));
    ref.invalidate(pendingSyncCountProvider);
  }

  /// Delete record
  Future<void> deleteRecord(String recordId) async {
    final record = _repository.getById(recordId);
    await _repository.delete(recordId);
    if (record != null) {
      ref.invalidate(maintenanceProvider(record.vehicleId));
      ref.invalidate(pendingSyncCountProvider);
    }
  }

  /// Delete all records for a vehicle
  Future<void> deleteByVehicleId(String vehicleId) async {
    await _repository.deleteByVehicleId(vehicleId);
    ref.invalidate(maintenanceProvider(vehicleId));
  }

  /// Sync pending changes to cloud
  Future<int> syncPending() async {
    return await _repository.syncPending();
  }

  /// Pull records from cloud for a vehicle
  Future<void> pullFromCloud(String vehicleId) async {
    await _repository.pullFromCloud(vehicleId);
    ref.invalidate(maintenanceProvider(vehicleId));
  }

  /// Get count of records needing sync
  int get pendingSyncCount => _repository.getPendingSyncCount();

  /// Assign user ID to all records (for migration)
  Future<void> assignUserToAllRecords(String userId) async {
    await _repository.assignUserToAllRecords(userId);
  }
}

// Provider for maintenance records for a specific vehicle
final maintenanceProvider = Provider.family<List<MaintenanceRecord>, String>((
  ref,
  vehicleId,
) {
  final repository = ref.watch(maintenanceRepositoryProvider);
  return repository.getByVehicleId(vehicleId);
});

/// Provider for total pending sync count (vehicles + maintenance)
/// This is reactive - rebuilds when data changes
final pendingSyncCountProvider = Provider<int>((ref) {
  final vehicleRepo = ref.watch(vehicleRepositoryProvider);
  final maintenanceRepo = ref.watch(maintenanceRepositoryProvider);
  final receiptRepo = ReceiptRepository();

  return vehicleRepo.getPendingSyncCount() +
      maintenanceRepo.getPendingSyncCount() +
      receiptRepo.getPendingSyncCount();
});
