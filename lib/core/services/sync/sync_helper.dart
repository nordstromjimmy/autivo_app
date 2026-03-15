import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_manager.dart';
import '../../../features/vehicles/providers/vehicle_provider.dart';
import '../../../features/maintenance/providers/maintenance_provider.dart';
import '../../../features/receipts/providers/receipt_provider.dart';
import '../../utils/helpers/custom_snackbar.dart';

class SyncHelper {
  /// Perform full sync with migration
  /// Call this from anywhere in the app
  static Future<void> performFullSync(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Show loading
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

    try {
      final syncManager = ref.read(syncManagerProvider);
      final userId = syncManager.userId;

      // STEP 1: Migrate offline data first (CRITICAL!)
      if (userId != null && syncManager.hasLocalDataToMigrate()) {
        print('📦 Migrating offline data to user: $userId');
        await syncManager.migrateAnonymousData(userId);
        print('✅ Migration complete');
      }

      // STEP 2: Perform sync
      final result = await syncManager.fullSync();

      // STEP 3: Invalidate all providers
      ref.invalidate(receiptNotifierProvider);
      ref.invalidate(receiptByIdProvider);
      ref.invalidate(receiptsForVehicleProvider);
      ref.invalidate(receiptsForMaintenanceProvider);
      ref.invalidate(receiptPendingSyncCountProvider);
      ref.invalidate(pendingSyncCountProvider);
      ref.invalidate(vehiclesProvider);
      ref.invalidate(maintenanceProvider);

      // Close loading
      if (context.mounted) Navigator.pop(context);

      // Show result
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
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Synkronisering misslyckades: $e');
      }
    }
  }
}
