import 'package:hive_flutter/hive_flutter.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import 'maintenance_deletion_tracker.dart';

Future<void> clearAllLocalData() async {
  try {
    // Clear vehicles box
    if (Hive.isBoxOpen('vehicles')) {
      final vehiclesBox = Hive.box<Vehicle>('vehicles');
      await vehiclesBox.clear();
    } else {
      final vehiclesBox = await Hive.openBox<Vehicle>('vehicles');
      await vehiclesBox.clear();
      await vehiclesBox.close();
    }

    // Clear maintenance box
    if (Hive.isBoxOpen('maintenance_records')) {
      final maintenanceBox = Hive.box<MaintenanceRecord>('maintenance_records');
      await maintenanceBox.clear();
    } else {
      final maintenanceBox = await Hive.openBox<MaintenanceRecord>(
        'maintenance_records',
      );
      await maintenanceBox.clear();
      await maintenanceBox.close();
    }

    // Clear maintenance deletion tracker
    await MaintenanceDeletionTracker.clearAll();
  } catch (e) {
    print('❌ Error clearing local data: $e');
    rethrow;
  }
}
