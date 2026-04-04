import 'package:hive_flutter/hive_flutter.dart';
import '../../../features/maintenance/models/maintenance_record.dart';
import '../../../features/receipts/models/receipt.dart';
import '../../../features/vehicles/models/vehicle.dart';
import 'maintenance_deletion_tracker.dart';

Future<void> clearAllLocalData() async {
  try {
    await _clearBox<Vehicle>('vehicles');
    await _clearBox<MaintenanceRecord>('maintenance_records');
    await _clearBox<Receipt>('receipts');
    await MaintenanceDeletionTracker.clearAll();
  } catch (e) {
    rethrow;
  }
}

/// Clears a Hive box whether it is already open or not.
Future<void> _clearBox<T>(String boxName) async {
  if (Hive.isBoxOpen(boxName)) {
    await Hive.box<T>(boxName).clear();
  } else {
    final box = await Hive.openBox<T>(boxName);
    await box.clear();
    await box.close();
  }
}
