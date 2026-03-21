import 'package:shared_preferences/shared_preferences.dart';
import 'notification_types.dart';

class NotificationPreferences {
  static const _keyPrefix = 'notification_';

  /// Check if notification type is enabled
  Future<bool> isEnabled(NotificationType type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('${_keyPrefix}${type.name}_enabled') ??
        type.defaultEnabled;
  }

  /// Set notification type enabled state
  Future<void> setEnabled(NotificationType type, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_keyPrefix}${type.name}_enabled', enabled);
  }

  /// Get days before to notify
  Future<int> getDaysBefore(NotificationType type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${_keyPrefix}${type.name}_days_before') ??
        _getDefaultDaysBefore(type);
  }

  /// Set days before to notify
  Future<void> setDaysBefore(NotificationType type, int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_keyPrefix}${type.name}_days_before', days);
  }

  /// Get default days before for notification type
  int _getDefaultDaysBefore(NotificationType type) {
    switch (type) {
      case NotificationType.inspectionReminder:
        return 14; // 2 weeks
      case NotificationType.serviceReminder:
        return 7; // 1 week
      case NotificationType.insuranceRenewal:
        return 30; // 1 month
      case NotificationType.maintenanceDue:
        return 7;
      case NotificationType.fuelReminder:
        return 1;
    }
  }
}
