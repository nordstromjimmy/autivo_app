import 'package:hive_flutter/hive_flutter.dart';

/// Tracks vehicles deleted while offline so we can sync deletions
class DeletionTracker {
  static const String _boxName = 'deletions';
  static const String _vehiclesKey = 'deleted_vehicles';

  /// Initialize the deletion tracker (call in main.dart)
  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  /// Track a vehicle deletion
  static Future<void> trackVehicleDeletion(String vehicleId) async {
    try {
      final box = await _ensureBoxOpen();
      final deletedVehicles = getDeletedVehicles();

      if (!deletedVehicles.contains(vehicleId)) {
        deletedVehicles.add(vehicleId);
        await box.put(_vehiclesKey, deletedVehicles);
        print('✅ Tracked deletion: $vehicleId');
      }
    } catch (e) {
      print('Error tracking deletion: $e');
    }
  }

  /// Get list of vehicles deleted while offline
  static List<String> getDeletedVehicles() {
    try {
      if (!Hive.isBoxOpen(_boxName)) return [];

      final box = Hive.box(_boxName);
      final list = box.get(_vehiclesKey);

      if (list == null) return [];
      return List<String>.from(list);
    } catch (e) {
      print('Error getting deleted vehicles: $e');
      return [];
    }
  }

  /// Clear tracked deletions (after successful sync)
  static Future<void> clearDeletedVehicles() async {
    try {
      final box = await _ensureBoxOpen();
      await box.delete(_vehiclesKey);
      print('✅ Cleared deletion tracker');
    } catch (e) {
      print('Error clearing deletions: $e');
    }
  }

  /// Clear ALL tracked data (on account switch)
  static Future<void> clearAll() async {
    try {
      final box = await _ensureBoxOpen();
      await box.clear();
      print('✅ Cleared all deletion tracking');
    } catch (e) {
      print('Error clearing all: $e');
    }
  }

  /// Ensure box is open
  static Future<Box> _ensureBoxOpen() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    } else {
      return await Hive.openBox(_boxName);
    }
  }
}
