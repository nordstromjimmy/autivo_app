import 'package:hive_flutter/hive_flutter.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';
import 'deletion_tracker.dart';

Future<void> clearAllLocalData() async {
  try {
    // Clear vehicles box
    if (Hive.isBoxOpen('vehicles')) {
      // Box is already open - use it
      final vehiclesBox = Hive.box<Vehicle>('vehicles');
      await vehiclesBox.clear();
      print('✅ Cleared open vehicles box');
    } else {
      // Box is not open - open, clear, then close
      final vehiclesBox = await Hive.openBox<Vehicle>('vehicles');
      await vehiclesBox.clear();
      await vehiclesBox.close();
      print('✅ Opened, cleared, and closed vehicles box');
    }

    // Clear maintenance box
    if (Hive.isBoxOpen('maintenance')) {
      final maintenanceBox = Hive.box<MaintenanceRecord>('maintenance');
      await maintenanceBox.clear();
      print('✅ Cleared open maintenance box');
    } else {
      final maintenanceBox = await Hive.openBox<MaintenanceRecord>(
        'maintenance',
      );
      await maintenanceBox.clear();
      await maintenanceBox.close();
      print('✅ Opened, cleared, and closed maintenance box');
    }
    await DeletionTracker.clearAll();

    print('✅ All local data cleared successfully');
  } catch (e) {
    print('❌ Error clearing local data: $e');
    rethrow;
  }
}
