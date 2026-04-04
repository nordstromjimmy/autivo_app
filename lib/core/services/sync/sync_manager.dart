import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/maintenance/repositories/maintenance_repository.dart';
import '../../../features/receipts/providers/receipt_provider.dart';
import '../../../features/receipts/repositories/receipt_repository.dart';
import '../../../features/vehicles/providers/vehicle_provider.dart';
import '../../../features/maintenance/providers/maintenance_provider.dart';
import '../../../features/vehicles/repositories/vehicle_repository.dart';
import '../../config/supabase_config.dart';
import '../../utils/helpers/custom_snackbar.dart';
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

  bool get isSignedIn => SupabaseConfig.isSignedIn;
  String? get userId => SupabaseConfig.currentUserId;

  int get totalPendingCount {
    return _vehicleRepo.getPendingSyncCount() +
        _maintenanceRepo.getPendingSyncCount() +
        _receiptRepo.getPendingSyncCount();
  }

  Future<bool> canSync() async {
    return await _syncService.canSync();
  }

  // ==================== SYNC OPERATIONS ====================

  /// Perform full sync.
  /// Push FIRST so local offline edits reach the cloud before we pull
  /// and merge — this prevents the cloud version overwriting local changes
  /// when timestamps are close or when supabaseId wasn't set yet.
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
      // Step 1: Push local changes first so the cloud has the latest
      // before we pull and merge
      final vehiclesSynced = await _vehicleRepo.syncPending();
      final recordsSynced = await _maintenanceRepo.syncPending();
      final receiptsSynced = await _receiptRepo.syncPending();

      // Step 2: Pull from cloud (safe now — local changes are already uploaded)
      await _vehicleRepo.pullFromCloud();

      final vehicles = _vehicleRepo.getAll();
      for (final vehicle in vehicles) {
        await _maintenanceRepo.pullFromCloud(vehicle.id);
        await _receiptRepo.pullFromCloud(vehicle.id);
      }

      // Step 3: Refresh UI
      _invalidateAllProviders();

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

  /// Perform full sync with optional UI feedback
  Future<SyncResult> performFullSyncWithUI(
    BuildContext context,
    WidgetRef ref, {
    bool showLoadingDialog = true,
  }) async {
    if (showLoadingDialog) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Synkroniserar...'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    try {
      // Migrate anonymous data if needed (e.g. after signup)
      if (userId != null && hasLocalDataToMigrate()) {
        await migrateAnonymousData(userId!);
      }

      debugPrint('=== BEFORE FULL SYNC ===');
      final vehicles = _vehicleRepo.getAll();
      for (final v in vehicles) {
        debugPrint('${v.registrationNumber} | needsSync: ${v.needsSync}');
      }

      final result = await fullSync();

      _invalidateAllProviders();

      if (showLoadingDialog && context.mounted) Navigator.pop(context);

      if (context.mounted) {
        if (result.success) {
          if (result.totalSynced > 0) {
            CustomSnackBar.showSuccess(context, result.toString());
          } else {
            CustomSnackBar.showSuccess(context, 'Allt synkroniserat');
          }
        } else {
          CustomSnackBar.showError(context, result.message);
        }
      }

      return result;
    } catch (e) {
      if (showLoadingDialog && context.mounted) Navigator.pop(context);
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Synkronisering misslyckades: $e');
      }

      return SyncResult(
        success: false,
        message: 'Synkronisering misslyckades: $e',
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

      _invalidateAllProviders();

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

      _invalidateAllProviders();

      return SyncResult(
        success: true,
        message: 'Nerladdning lyckades',
        vehiclesSynced: vehicles.length,
        recordsSynced: 0,
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

  /// Assign user ID to all anonymous local data (called after signup)
  Future<void> migrateAnonymousData(String userId) async {
    await _vehicleRepo.assignUserToAllVehicles(userId);
    await _maintenanceRepo.assignUserToAllRecords(userId);
    await _receiptRepo.assignUserToAllReceipts(userId);
  }

  /// Check if there is any local data without a userId (anonymous data)
  bool hasLocalDataToMigrate() {
    final hasVehicles = _vehicleRepo.getAll().any(
      (v) => v.userId == null || v.userId!.isEmpty,
    );

    final hasReceipts = _receiptRepo.getAll().any((r) => r.userId.isEmpty);

    final hasMaintenance = _maintenanceRepo.getAll().any(
      (m) => m.userId == null || m.userId!.isEmpty,
    );

    return hasVehicles || hasReceipts || hasMaintenance;
  }

  // ==================== HELPERS ====================

  void _invalidateAllProviders() {
    _ref.invalidate(vehiclesNotifierProvider);
    _ref.invalidate(vehiclesProvider);
    _ref.invalidate(maintenanceProvider);
    _ref.invalidate(receiptNotifierProvider);
    _ref.invalidate(receiptByIdProvider);
    _ref.invalidate(receiptsForVehicleProvider);
    _ref.invalidate(receiptsForMaintenanceProvider);
    _ref.invalidate(pendingSyncCountProvider);
    _ref.invalidate(receiptPendingSyncCountProvider);
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

    final parts = <String>[];
    if (vehiclesSynced > 0) parts.add('$vehiclesSynced fordon');
    if (recordsSynced > 0) parts.add('$recordsSynced poster');
    if (receiptsSynced > 0) parts.add('$receiptsSynced kvitton');

    return 'Synkroniserat: ${parts.join(', ')}';
  }
}
