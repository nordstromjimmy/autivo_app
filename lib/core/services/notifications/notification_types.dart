/// Notification type definitions
enum NotificationType { inspectionReminder, serviceReminder, maintenanceDue }

extension NotificationTypeExtension on NotificationType {
  /// Channel ID for Android
  String get channelId {
    switch (this) {
      case NotificationType.inspectionReminder:
        return 'inspection_reminders';
      case NotificationType.serviceReminder:
        return 'service_reminders';

      case NotificationType.maintenanceDue:
        return 'maintenance_due';
    }
  }

  /// Channel name (user-visible)
  String get channelName {
    switch (this) {
      case NotificationType.inspectionReminder:
        return 'Besiktningspåminnelser';
      case NotificationType.serviceReminder:
        return 'Servicepåminnelser';

      case NotificationType.maintenanceDue:
        return 'Underhåll förfaller';
    }
  }

  /// Channel description
  String get channelDescription {
    switch (this) {
      case NotificationType.inspectionReminder:
        return 'Påminnelser om kommande besiktningar';
      case NotificationType.serviceReminder:
        return 'Påminnelser om servicetillfällen';

      case NotificationType.maintenanceDue:
        return 'Påminnelser när underhåll förfaller';
    }
  }

  /// Default enabled state
  bool get defaultEnabled {
    switch (this) {
      case NotificationType.inspectionReminder:
        return true; // Important, enable by default
      case NotificationType.serviceReminder:
        return true;

      case NotificationType.maintenanceDue:
        return false; // Less critical
    }
  }

  /// Icon for UI
  String get icon {
    switch (this) {
      case NotificationType.inspectionReminder:
        return '🔍';
      case NotificationType.serviceReminder:
        return '🔧';

      case NotificationType.maintenanceDue:
        return '⏰';
    }
  }
}
