import 'package:hive_flutter/hive_flutter.dart';

/// Tracks the last logged in user to detect account switches
class UserSessionTracker {
  static const String _boxName = 'user_session';
  static const String _userIdKey = 'last_user_id';

  /// Initialize the session tracker (call in main.dart)
  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  /// Get the last logged in user ID
  static String? getLastUserId() {
    try {
      if (!Hive.isBoxOpen(_boxName)) return null;

      final box = Hive.box(_boxName);
      return box.get(_userIdKey) as String?;
    } catch (e) {
      return null;
    }
  }

  /// Save current user ID
  static Future<void> saveUserId(String userId) async {
    try {
      final box = await _ensureBoxOpen();
      await box.put(_userIdKey, userId);
    } catch (e) {
      print('Error saving user ID: $e');
    }
  }

  /// Clear saved user ID (on logout)
  static Future<void> clearUserId() async {
    try {
      final box = await _ensureBoxOpen();
      await box.delete(_userIdKey);
    } catch (e) {
      print('Error clearing user ID: $e');
    }
  }

  /// Check if this is a different user logging in
  static bool isDifferentUser(String newUserId) {
    final lastUserId = getLastUserId();

    // No previous user = first time (not different)
    if (lastUserId == null) return false;

    // Different user ID = account switch
    return lastUserId != newUserId;
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
