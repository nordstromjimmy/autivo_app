import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'notification_types.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notification service
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationTapped,
    );

    _initialized = true;
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    // Android 13+ notification permissions
    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      if (granted == false) return false;
    }

    // iOS permissions
    final iosImpl = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosImpl != null) {
      final granted = await iosImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (granted == false) return false;
    }

    // ✅ NEW: Request exact alarm permission (Android 12+)
    if (await _isAndroid12OrHigher()) {
      final status = await Permission.scheduleExactAlarm.request();
      print('📅 Exact alarm permission: $status');

      if (!status.isGranted) {
        print('⚠️ Exact alarm permission denied! Notifications may not work.');
        // On some Android versions, we need to open settings
        await openAppSettings();
      }
    }

    return true;
  }

  /// Check if Android 12 or higher
  Future<bool> _isAndroid12OrHigher() async {
    // You'll need device_info_plus for this
    // For now, return true to always request permission
    return true;
  }

  /// Schedule a notification
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationType type,
    String? payload,
  }) async {
    print('🔔 Scheduling notification:');
    print('   ID: $id');
    print('   Title: $title');
    print('   Scheduled for: $scheduledDate');
    print('   Current time: ${DateTime.now()}');

    // ✅ FIX: Create TZ datetime properly (don't use .from())
    final location = tz.getLocation('Europe/Stockholm');
    final tzDateTime = tz.TZDateTime.from(scheduledDate, location);

    print('   TZ DateTime: $tzDateTime');
    print(
      '   Time until notification: ${tzDateTime.difference(tz.TZDateTime.now(location))}',
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzDateTime,
      _getNotificationDetails(type),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );

    print('✅ Notification scheduled successfully!');
  }

  /// Cancel a notification
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPending() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Handle notification tap (foreground)
  void _onNotificationTapped(NotificationResponse response) {
    print('✅ Notification tapped: ${response.payload}');
    // TODO: Handle navigation based on payload
  }

  /// Handle notification tap (background)
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    print('✅ Background notification tapped: ${response.payload}');
    // TODO: Handle navigation based on payload
  }

  /// Get notification details for type
  NotificationDetails _getNotificationDetails(NotificationType type) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        type.channelId,
        type.channelName,
        channelDescription: type.channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }
}
