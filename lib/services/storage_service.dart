import 'package:hive/hive.dart';
import '../models/vehicle.dart';
import '../models/maintenance_record.dart';
import '../models/checklist_state.dart';

class StorageService {
  // Box getters (assumes boxes are already opened in main.dart)
  static Box<Vehicle> get _vehicleBox => Hive.box<Vehicle>('vehicles');
  static Box<MaintenanceRecord> get _maintenanceBox =>
      Hive.box<MaintenanceRecord>('maintenance');
  static Box<ChecklistState> get _checklistBox =>
      Hive.box<ChecklistState>('checklist');

  // ==================== VEHICLE METHODS ====================

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
    final toDelete = _maintenanceBox.values
        .where((record) => record.vehicleId == id)
        .toList();
    for (var record in toDelete) {
      await _maintenanceBox.delete(record.id);
    }

    // Also delete related checklist state
    await deleteChecklistState(id);
  }

  static Vehicle? getVehicle(String id) {
    return _vehicleBox.get(id);
  }

  // ==================== MAINTENANCE METHODS ====================

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

  static MaintenanceRecord? getMaintenanceRecord(String id) {
    return _maintenanceBox.get(id);
  }

  // ==================== CHECKLIST METHODS ====================

  static Future<void> saveChecklistState(ChecklistState state) async {
    await _checklistBox.put(state.vehicleId, state);
  }

  static ChecklistState? getChecklistState(String vehicleId) {
    return _checklistBox.get(vehicleId);
  }

  static Future<void> deleteChecklistState(String vehicleId) async {
    await _checklistBox.delete(vehicleId);
  }

  static Future<void> clearChecklistState(String vehicleId) async {
    final state = getChecklistState(vehicleId);
    if (state != null) {
      // Create a NEW state object instead of mutating
      final newCheckedItems = <String, bool>{};
      for (var key in state.checkedItems.keys) {
        newCheckedItems[key] = false;
      }

      final newState = ChecklistState(
        vehicleId: vehicleId,
        checkedItems: newCheckedItems,
        lastUpdated: DateTime.now(),
        lastCompleted: null,
      );

      await _checklistBox.put(vehicleId, newState);
    }
  }
}
