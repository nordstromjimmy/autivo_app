import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service.dart';
import 'notification_types.dart';
import 'notification_preferences.dart';

/// Centralized notification scheduler
class NotificationScheduler {
  final NotificationService _service;
  final NotificationPreferences _preferences;

  NotificationScheduler(this._service, this._preferences);

  /// Schedule inspection reminder
  Future<void> scheduleInspectionReminder({
    required String vehicleId,
    required String vehicleRegNumber,
    required DateTime inspectionDate,
  }) async {
    if (!await _preferences.isEnabled(NotificationType.inspectionReminder)) {
      return;
    }

    final daysBefore = await _preferences.getDaysBefore(
      NotificationType.inspectionReminder,
    );

    final notificationDate = inspectionDate.subtract(
      Duration(days: daysBefore),
    );

    // Don't schedule if in the past
    if (notificationDate.isBefore(DateTime.now())) return;

    final notificationId = _getNotificationId(
      NotificationType.inspectionReminder,
      vehicleId,
    );

    await _service.schedule(
      id: notificationId,
      title: 'Besiktning snart för $vehicleRegNumber',
      body: 'Din besiktning är om $daysBefore dagar',
      scheduledDate: notificationDate,
      type: NotificationType.inspectionReminder,
      payload: 'vehicle:$vehicleId',
    );
  }

  /// Cancel inspection reminder
  Future<void> cancelInspectionReminder(String vehicleId) async {
    final id = _getNotificationId(
      NotificationType.inspectionReminder,
      vehicleId,
    );
    await _service.cancel(id);
  }

  /// Schedule insurance renewal reminder
  Future<void> scheduleInsuranceRenewal({
    required String vehicleId,
    required String vehicleRegNumber,
    required DateTime renewalDate,
  }) async {
    if (!await _preferences.isEnabled(NotificationType.insuranceRenewal)) {
      return;
    }

    final daysBefore = await _preferences.getDaysBefore(
      NotificationType.insuranceRenewal,
    );

    final notificationDate = renewalDate.subtract(Duration(days: daysBefore));

    if (notificationDate.isBefore(DateTime.now())) return;

    final notificationId = _getNotificationId(
      NotificationType.insuranceRenewal,
      vehicleId,
    );

    await _service.schedule(
      id: notificationId,
      title: 'Försäkring förnyelse för $vehicleRegNumber',
      body: 'Din försäkring förfaller om $daysBefore dagar',
      scheduledDate: notificationDate,
      type: NotificationType.insuranceRenewal,
      payload: 'vehicle:$vehicleId:insurance',
    );
  }

  /// Reschedule all notifications for a vehicle
  Future<void> rescheduleForVehicle(
    String vehicleId,
    String regNumber,
    DateTime? inspectionDate,
    DateTime? insuranceRenewal,
  ) async {
    // Cancel existing
    await cancelInspectionReminder(vehicleId);

    // Schedule new
    if (inspectionDate != null) {
      await scheduleInspectionReminder(
        vehicleId: vehicleId,
        vehicleRegNumber: regNumber,
        inspectionDate: inspectionDate,
      );
    }

    if (insuranceRenewal != null) {
      await scheduleInsuranceRenewal(
        vehicleId: vehicleId,
        vehicleRegNumber: regNumber,
        renewalDate: insuranceRenewal,
      );
    }
  }

  /// Generate unique notification ID
  int _getNotificationId(NotificationType type, String entityId) {
    // Combine type index and entity hash for unique ID
    final typeId = type.index * 1000000;
    final entityHash = entityId.hashCode.abs() % 1000000;
    return typeId + entityHash;
  }
}

final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  return NotificationScheduler(
    NotificationService(),
    NotificationPreferences(),
  );
});
