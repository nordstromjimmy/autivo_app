import 'package:hive/hive.dart';
import '../../../features/vehicles/models/vehicle.dart';
import '../../../features/maintenance/models/maintenance_record.dart';
import '../../../features/inspection/models/checklist_state.dart';

class StorageService {
  static Box<Vehicle> get _vehicleBox => Hive.box<Vehicle>('vehicles');
  static Box<MaintenanceRecord> get _maintenanceBox =>
      Hive.box<MaintenanceRecord>('maintenance_records');
  static Box<ChecklistState> get _checklistBox =>
      Hive.box<ChecklistState>('checklist');

  // ==================== VEHICLE METHODS ====================

  /// Get all vehicles sorted by creation date (newest first)
  static List<Vehicle> getAllVehicles() {
    return _vehicleBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Delete a vehicle and its related maintenance records
  static Future<void> deleteVehicle(String id) async {
    await _vehicleBox.delete(id);

    final toDelete = _maintenanceBox.values
        .where((record) => record.vehicleId == id)
        .toList();
    for (final record in toDelete) {
      await _maintenanceBox.delete(record.id);
    }

    await deleteChecklistState(id);
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
    if (state == null) return;

    final newCheckedItems = {
      for (final key in state.checkedItems.keys) key: false,
    };

    await _checklistBox.put(
      vehicleId,
      ChecklistState(
        vehicleId: vehicleId,
        checkedItems: newCheckedItems,
        lastUpdated: DateTime.now(),
        lastCompleted: null,
      ),
    );
  }
}
