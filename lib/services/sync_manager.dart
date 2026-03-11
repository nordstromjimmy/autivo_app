import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/maintenance_repository.dart';
import '../providers/vehicle_provider.dart';
import '../providers/maintenance_provider.dart';
import '../repositories/vehicle_repository.dart';
import '../services/supabase_config.dart';
import '../services/sync_service.dart';

// Provider for sync manager
final syncManagerProvider = Provider((ref) => SyncManager(ref));

class SyncManager {
  final Ref _ref;
  final SyncService _syncService = SyncService();

  SyncManager(this._ref);

  VehicleRepository get _vehicleRepo => _ref.read(vehicleRepositoryProvider);
  MaintenanceRepository get _maintenanceRepo =>
      _ref.read(maintenanceRepositoryProvider);

  // ==================== SYNC STATUS ====================

  /// Check if user is signed in
  bool get isSignedIn => SupabaseConfig.isSignedIn;

  /// Get current user ID
  String? get userId => SupabaseConfig.currentUserId;

  /// Get total count of items needing sync
  int get totalPendingCount {
    return _vehicleRepo.getPendingSyncCount() +
        _maintenanceRepo.getPendingSyncCount();
  }

  /// Check if device can sync (has internet)
  Future<bool> canSync() async {
    return await _syncService.canSync();
  }

  // ==================== SYNC OPERATIONS ====================

  /// Perform full sync (pull then push for all data)
  Future<SyncResult> fullSync() async {
    if (!isSignedIn) {
      return SyncResult(
        success: false,
        message: 'Logga in för att synkronisera',
        vehiclesSynced: 0,
        recordsSynced: 0,
      );
    }

    if (!await canSync()) {
      return SyncResult(
        success: false,
        message: 'Ingen internetanslutning',
        vehiclesSynced: 0,
        recordsSynced: 0,
      );
    }

    try {
      // Step 1: Pull from cloud first
      await _vehicleRepo.pullFromCloud();

      // Step 2: Pull maintenance records for all vehicles
      final vehicles = _vehicleRepo.getAll();
      for (final vehicle in vehicles) {
        await _maintenanceRepo.pullFromCloud(vehicle.id);
      }

      // Step 3: Push pending changes
      final vehiclesSynced = await _vehicleRepo.syncPending();
      final recordsSynced = await _maintenanceRepo.syncPending();

      // Step 4: Refresh providers to update UI
      _refreshProviders();

      return SyncResult(
        success: true,
        message: 'Sync lyckades',
        vehiclesSynced: vehiclesSynced,
        recordsSynced: recordsSynced,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Sync misslyckades: $e',
        vehiclesSynced: 0,
        recordsSynced: 0,
      );
    }
  }

  /// Push only (upload pending changes)
  Future<SyncResult> pushOnly() async {
    if (!isSignedIn) {
      return SyncResult(
        success: false,
        message: 'Du är inte inloggad',
        vehiclesSynced: 0,
        recordsSynced: 0,
      );
    }

    try {
      final vehiclesSynced = await _vehicleRepo.syncPending();
      final recordsSynced = await _maintenanceRepo.syncPending();

      // Refresh providers to update UI
      _refreshProviders();

      return SyncResult(
        success: true,
        message: 'Uppladdning lyckades',
        vehiclesSynced: vehiclesSynced,
        recordsSynced: recordsSynced,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Uppladdning misslyckades: $e',
        vehiclesSynced: 0,
        recordsSynced: 0,
      );
    }
  }

  /// Pull only (download from cloud)
  Future<SyncResult> pullOnly() async {
    if (!isSignedIn) {
      return SyncResult(
        success: false,
        message: 'Du är inte inloggad',
        vehiclesSynced: 0,
        recordsSynced: 0,
      );
    }

    try {
      await _vehicleRepo.pullFromCloud();

      final vehicles = _vehicleRepo.getAll();
      for (final vehicle in vehicles) {
        await _maintenanceRepo.pullFromCloud(vehicle.id);
      }

      // Refresh providers to update UI
      _refreshProviders();

      return SyncResult(
        success: true,
        message: 'Nerladdning lyckades',
        vehiclesSynced: vehicles.length,
        recordsSynced: 0, // We don't track this separately
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Nerladdning misslyckades: $e',
        vehiclesSynced: 0,
        recordsSynced: 0,
      );
    }
  }

  // ==================== USER MIGRATION ====================

  /// When user signs up/in - assign their ID to all existing data
  Future<void> migrateAnonymousData(String userId) async {
    await _vehicleRepo.assignUserToAllVehicles(userId);
    await _maintenanceRepo.assignUserToAllRecords(userId);

    // Upload everything to cloud
    await pushOnly();
  }

  /// Check if user has any local data to migrate
  bool hasLocalDataToMigrate() {
    final vehicles = _vehicleRepo.getAll();
    return vehicles.any((v) => v.userId == null);
  }

  // ==================== HELPERS ====================

  /// Refresh providers to update UI after sync
  void _refreshProviders() {
    // Refresh vehicles provider
    _ref.read(vehiclesProvider.notifier).refresh();

    // Note: Maintenance provider refreshes automatically when vehicles change
    // because it uses provider.family which is invalidated per vehicle
  }
}

// ==================== SYNC RESULT ====================

class SyncResult {
  final bool success;
  final String message;
  final int vehiclesSynced;
  final int recordsSynced;

  SyncResult({
    required this.success,
    required this.message,
    required this.vehiclesSynced,
    required this.recordsSynced,
  });

  int get totalSynced => vehiclesSynced + recordsSynced;

  @override
  String toString() {
    if (!success) return message;
    if (totalSynced == 0) return 'Allting syncat';
    return 'Synkroniserat: $vehiclesSynced fordon, $recordsSynced poster';
  }
}
