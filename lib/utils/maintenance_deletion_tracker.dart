import 'package:hive/hive.dart';

/// Tracks maintenance records deleted while offline
/// So they can be deleted from cloud when user logs back in
class MaintenanceDeletionTracker {
  static const String boxName = 'maintenance_deletions';

  static Box<String>? _box;

  /// Initialize the tracker (call in main.dart)
  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(boxName)) {
      _box = await Hive.openBox<String>(boxName);
    } else {
      _box = Hive.box<String>(boxName);
    }
  }

  /// Track a maintenance record deletion
  static Future<void> trackDeletion(String recordId) async {
    if (_box == null) {
      throw Exception('MaintenanceDeletionTracker not initialized');
    }

    // Store the record ID with current timestamp as key
    final key = '${DateTime.now().millisecondsSinceEpoch}_$recordId';
    await _box!.put(key, recordId);
  }

  /// Get all deleted record IDs
  static Set<String> getDeletedRecords() {
    if (_box == null) return {};
    return _box!.values.toSet();
  }

  /// Clear all tracked deletions
  static Future<void> clearDeletedRecords() async {
    if (_box == null) return;
    await _box!.clear();
  }

  /// Clear all data (for account switching)
  static Future<void> clearAll() async {
    if (_box == null) return;
    await _box!.clear();
  }

  /// Check if a record ID is tracked as deleted
  static bool isDeleted(String recordId) {
    if (_box == null) return false;
    return _box!.values.contains(recordId);
  }
}
