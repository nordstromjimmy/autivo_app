import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/maintenance/repositories/maintenance_repository.dart';
import '../../../features/receipts/repositories/receipt_repository.dart';
import '../../../features/vehicles/providers/vehicle_provider.dart';
import '../../../features/maintenance/providers/maintenance_provider.dart';
import '../../../features/vehicles/repositories/vehicle_repository.dart';
import '../../config/supabase_config.dart';
import 'sync_service.dart';

// Provider for sync manager
final syncManagerProvider = Provider((ref) => SyncManager(ref));

class SyncManager {
  final Ref _ref;
  final SyncService _syncService = SyncService();

  SyncManager(this._ref);

  VehicleRepository get _vehicleRepo => _ref.read(vehicleRepositoryProvider);
  MaintenanceRepository get _maintenanceRepo =>
      _ref.read(maintenanceRepositoryProvider);
  ReceiptRepository get _receiptRepo => ReceiptRepository();

  // ==================== SYNC STATUS ====================

  /// Check if user is signed in
  bool get isSignedIn => SupabaseConfig.isSignedIn;

  /// Get current user ID
  String? get userId => SupabaseConfig.currentUserId;

  /// Get total count of items needing sync
  int get totalPendingCount {
    return _vehicleRepo.getPendingSyncCount() +
        _maintenanceRepo.getPendingSyncCount() +
        _receiptRepo.getPendingSyncCount();
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
        receiptsSynced: 0,
      );
    }

    if (!await canSync()) {
      return SyncResult(
        success: false,
        message: 'Ingen internetanslutning',
        vehiclesSynced: 0,
        recordsSynced: 0,
        receiptsSynced: 0,
      );
    }

    try {
      // Step 1: Pull from cloud first
      await _vehicleRepo.pullFromCloud();

      // Step 2: Pull maintenance records and receipts for all vehicles
      final vehicles = _vehicleRepo.getAll();
      for (final vehicle in vehicles) {
        await _maintenanceRepo.pullFromCloud(vehicle.id);
        await _receiptRepo.pullFromCloud(vehicle.id);
      }

      // Step 3: Push pending changes
      final vehiclesSynced = await _vehicleRepo.syncPending();
      final recordsSynced = await _maintenanceRepo.syncPending();
      final receiptsSynced = await _receiptRepo.syncPending();

      // Step 4: Refresh providers to update UI
      _refreshProviders();

      return SyncResult(
        success: true,
        message: 'Sync lyckades',
        vehiclesSynced: vehiclesSynced,
        recordsSynced: recordsSynced,
        receiptsSynced: receiptsSynced,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Sync misslyckades: $e',
        vehiclesSynced: 0,
        recordsSynced: 0,
        receiptsSynced: 0,
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
        receiptsSynced: 0,
      );
    }

    try {
      final vehiclesSynced = await _vehicleRepo.syncPending();
      final recordsSynced = await _maintenanceRepo.syncPending();
      final receiptsSynced = await _receiptRepo.syncPending();

      // Refresh providers to update UI
      _refreshProviders();

      return SyncResult(
        success: true,
        message: 'Uppladdning lyckades',
        vehiclesSynced: vehiclesSynced,
        recordsSynced: recordsSynced,
        receiptsSynced: receiptsSynced,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Uppladdning misslyckades: $e',
        vehiclesSynced: 0,
        recordsSynced: 0,
        receiptsSynced: 0,
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
        receiptsSynced: 0,
      );
    }

    try {
      await _vehicleRepo.pullFromCloud();

      final vehicles = _vehicleRepo.getAll();
      for (final vehicle in vehicles) {
        await _maintenanceRepo.pullFromCloud(vehicle.id);
        await _receiptRepo.pullFromCloud(vehicle.id);
      }

      // Refresh providers to update UI
      _refreshProviders();

      return SyncResult(
        success: true,
        message: 'Nerladdning lyckades',
        vehiclesSynced: vehicles.length,
        recordsSynced: 0, // We don't track this separately
        receiptsSynced: 0,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Nerladdning misslyckades: $e',
        vehiclesSynced: 0,
        recordsSynced: 0,
        receiptsSynced: 0,
      );
    }
  }

  // ==================== USER MIGRATION ====================

  /// When user signs up/in - assign their ID to all existing data
  Future<void> migrateAnonymousData(String userId) async {
    await _vehicleRepo.assignUserToAllVehicles(userId);
    await _maintenanceRepo.assignUserToAllRecords(userId);
    await _receiptRepo.assignUserToAllReceipts(userId);

    // Upload everything to cloud
    await pushOnly();
  }

  /// Check if user has any local data to migrate
  bool hasLocalDataToMigrate() {
    // Check vehicles
    final vehicles = _vehicleRepo.getAll();
    final hasVehicles = vehicles.any(
      (v) => v.userId == null || v.userId!.isEmpty,
    );

    // Check receipts
    final receipts = _receiptRepo.getAll();
    final hasReceipts = receipts.any((r) => r.userId.isEmpty);

    // Check maintenance records
    final maintenance = _maintenanceRepo.getAll();
    final hasMaintenance = maintenance.any(
      (m) => m.userId == null || m.userId!.isEmpty,
    );

    final needsMigration = hasVehicles || hasReceipts || hasMaintenance;

    if (needsMigration) {
      print('ℹ️ Found data needing migration:');
      if (hasVehicles) print('  - Vehicles without userId');
      if (hasReceipts) print('  - Receipts without userId');
      if (hasMaintenance) print('  - Maintenance without userId');
    }

    return needsMigration;
  }

  // ==================== HELPERS ====================

  /// Refresh providers to update UI after sync
  void _refreshProviders() {
    // Refresh vehicles provider
    _ref.read(vehiclesProvider.notifier).refresh();

    // Note: Maintenance and receipt providers refresh automatically when vehicles change
    // because they use provider.family which is invalidated per vehicle
  }
}

// ==================== SYNC RESULT ====================

class SyncResult {
  final bool success;
  final String message;
  final int vehiclesSynced;
  final int recordsSynced;
  final int receiptsSynced;

  SyncResult({
    required this.success,
    required this.message,
    required this.vehiclesSynced,
    required this.recordsSynced,
    required this.receiptsSynced,
  });

  int get totalSynced => vehiclesSynced + recordsSynced + receiptsSynced;

  @override
  String toString() {
    if (!success) return message;
    if (totalSynced == 0) return 'Allting syncat';

    // Include receipts in message
    final parts = <String>[];
    if (vehiclesSynced > 0) parts.add('$vehiclesSynced fordon');
    if (recordsSynced > 0) parts.add('$recordsSynced poster');
    if (receiptsSynced > 0) parts.add('$receiptsSynced kvitton');

    if (parts.isEmpty) return 'Allting syncat';
    return 'Synkroniserat: ${parts.join(', ')}';
  }
}
