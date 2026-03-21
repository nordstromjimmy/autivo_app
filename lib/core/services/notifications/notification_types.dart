/// Notification type definitions
enum NotificationType {
  inspectionReminder,
  serviceReminder,
  insuranceRenewal,
  maintenanceDue,
  fuelReminder,
}

extension NotificationTypeExtension on NotificationType {
  /// Channel ID for Android
  String get channelId {
    switch (this) {
      case NotificationType.inspectionReminder:
        return 'inspection_reminders';
      case NotificationType.serviceReminder:
        return 'service_reminders';
      case NotificationType.insuranceRenewal:
        return 'insurance_renewals';
      case NotificationType.maintenanceDue:
        return 'maintenance_due';
      case NotificationType.fuelReminder:
        return 'fuel_reminders';
    }
  }

  /// Channel name (user-visible)
  String get channelName {
    switch (this) {
      case NotificationType.inspectionReminder:
        return 'Besiktningspåminnelser';
      case NotificationType.serviceReminder:
        return 'Servicepåminnelser';
      case NotificationType.insuranceRenewal:
        return 'Försäkringsförnyelse';
      case NotificationType.maintenanceDue:
        return 'Underhåll förfaller';
      case NotificationType.fuelReminder:
        return 'Bränslepåminnelser';
    }
  }

  /// Channel description
  String get channelDescription {
    switch (this) {
      case NotificationType.inspectionReminder:
        return 'Påminnelser om kommande besiktningar';
      case NotificationType.serviceReminder:
        return 'Påminnelser om servicetillfällen';
      case NotificationType.insuranceRenewal:
        return 'Påminnelser om försäkringsförnyelse';
      case NotificationType.maintenanceDue:
        return 'Påminnelser när underhåll förfaller';
      case NotificationType.fuelReminder:
        return 'Påminnelser om bränslepåfyllning';
    }
  }

  /// Default enabled state
  bool get defaultEnabled {
    switch (this) {
      case NotificationType.inspectionReminder:
        return true; // Important, enable by default
      case NotificationType.serviceReminder:
        return true;
      case NotificationType.insuranceRenewal:
        return true;
      case NotificationType.maintenanceDue:
        return false; // Less critical
      case NotificationType.fuelReminder:
        return false;
    }
  }

  /// Icon for UI
  String get icon {
    switch (this) {
      case NotificationType.inspectionReminder:
        return '🔍';
      case NotificationType.serviceReminder:
        return '🔧';
      case NotificationType.insuranceRenewal:
        return '🛡️';
      case NotificationType.maintenanceDue:
        return '⏰';
      case NotificationType.fuelReminder:
        return '⛽';
    }
  }
}
