import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/maintenance_record.dart';
import '../services/storage_service.dart';

// Provider that watches the notifier state
final maintenanceProvider = Provider.family<List<MaintenanceRecord>, String>((
  ref,
  vehicleId,
) {
  // Watch the notifier - when it changes, this rebuilds
  ref.watch(maintenanceNotifierProvider);
  return StorageService.getMaintenanceForVehicle(vehicleId);
});

// Notifier for managing maintenance records
final maintenanceNotifierProvider =
    StateNotifierProvider<MaintenanceNotifier, int>((ref) {
      return MaintenanceNotifier();
    });

class MaintenanceNotifier extends StateNotifier<int> {
  MaintenanceNotifier() : super(0);

  Future<void> addRecord(MaintenanceRecord record) async {
    await StorageService.saveMaintenanceRecord(record);
    state++; // This triggers rebuild of any provider watching this
  }

  Future<void> deleteRecord(String id) async {
    await StorageService.deleteMaintenanceRecord(id);
    state++; // This triggers rebuild
  }
}
