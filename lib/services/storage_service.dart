import 'package:hive/hive.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';

class StorageService {
  // Vehicles
  static Box<Vehicle> get _vehicleBox => Hive.box<Vehicle>('vehicles');

  static List<Vehicle> getAllVehicles() {
    return _vehicleBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static Future<void> saveVehicle(Vehicle vehicle) async {
    await _vehicleBox.put(vehicle.id, vehicle);
  }

  static Future<void> deleteVehicle(String id) async {
    await _vehicleBox.delete(id);
    // Also delete related maintenance records
    final maintenanceBox = Hive.box<MaintenanceRecord>('maintenance');
    final toDelete = maintenanceBox.values
        .where((record) => record.vehicleId == id)
        .toList();
    for (var record in toDelete) {
      await record.delete();
    }
  }

  static Vehicle? getVehicle(String id) {
    return _vehicleBox.get(id);
  }

  // Maintenance
  static Box<MaintenanceRecord> get _maintenanceBox =>
      Hive.box<MaintenanceRecord>('maintenance');

  static List<MaintenanceRecord> getMaintenanceForVehicle(String vehicleId) {
    return _maintenanceBox.values
        .where((record) => record.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveMaintenanceRecord(MaintenanceRecord record) async {
    await _maintenanceBox.put(record.id, record);
  }

  static Future<void> deleteMaintenanceRecord(String id) async {
    await _maintenanceBox.delete(id);
  }
}
