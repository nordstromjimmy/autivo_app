import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/notifications/notification_service.dart';
import '../core/services/notifications/notification_types.dart';
import '../core/services/notifications/notification_preferences.dart';
import '../core/utils/helpers/custom_snackbar.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  final _preferences = NotificationPreferences();
  final _service = NotificationService();

  bool _permissionsGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);

    await _service.initialize();

    // Check if permissions are granted
    final notifStatus = await Permission.notification.status;
    final alarmStatus = await Permission.scheduleExactAlarm.status;

    setState(() {
      _permissionsGranted = notifStatus.isGranted && alarmStatus.isGranted;
      _isLoading = false;
    });
  }

  Future<void> _requestPermissions() async {
    final granted = await _service.requestPermissions();
    await _checkPermissions();

    if (mounted) {
      if (granted) {
        CustomSnackBar.showSuccess(
          context,
          'Behörigheter beviljade! Notifikationer är nu aktiverade.',
        );
      } else {
        CustomSnackBar.showError(
          context,
          'Behörigheter nekade. Aktivera i inställningar.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikationer')),
      body: ListView(
        children: [
          // Permission Status Card
          if (!_permissionsGranted)
            Card(
              color: Theme.of(context).colorScheme.surface,
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[800]),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Behörigheter krävs',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Autivo behöver behörighet för att skicka notifikationer om besiktning, service och försäkring.',
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _requestPermissions,
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Aktivera notifikationer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Enabled Status
          if (_permissionsGranted)
            Card(
              color: Theme.of(context).colorScheme.surface,
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Notifikationer är aktiverade',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Påminnelser',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Inspection Reminders
          _buildNotificationTypeTile(NotificationType.inspectionReminder),

          // Insurance Renewal
          //_buildNotificationTypeTile(NotificationType.insuranceRenewal),

          // Service Reminder
          //_buildNotificationTypeTile(NotificationType.serviceReminder),
          const Divider(),

          // View Pending Notifications
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('Visa schemalagda notifikationer'),
            subtitle: const Text('Se alla kommande påminnelser'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showPendingNotifications,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTypeTile(NotificationType type) {
    return FutureBuilder<bool>(
      future: _preferences.isEnabled(type),
      builder: (context, enabledSnapshot) {
        final isEnabled = enabledSnapshot.data ?? type.defaultEnabled;

        return FutureBuilder<int>(
          future: _preferences.getDaysBefore(type),
          builder: (context, daysSnapshot) {
            final daysBefore = daysSnapshot.data ?? 30; // ✅ Default to 30

            return ExpansionTile(
              leading: Text(type.icon, style: const TextStyle(fontSize: 24)),
              title: Text(type.channelName),
              subtitle: Text(
                isEnabled ? '$daysBefore dagar innan' : 'Inaktiverad',
                style: TextStyle(color: isEnabled ? Colors.green : Colors.grey),
              ),
              trailing: Switch(
                value: isEnabled && _permissionsGranted,
                onChanged: _permissionsGranted
                    ? (value) async {
                        await _preferences.setEnabled(type, value);
                        setState(() {});
                      }
                    : null,
              ),
              children: [
                if (isEnabled && _permissionsGranted)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Påminn mig:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [30].map((days) {
                            // Changed from [7, 14, 30]
                            return ChoiceChip(
                              label: Text('$days dagar innan'),
                              selected: daysBefore == days,
                              onSelected: (selected) async {
                                if (selected) {
                                  await _preferences.setDaysBefore(type, days);
                                  setState(() {});
                                }
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Du får en påminnelse 30 dagar innan ${_getEventName(type)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // Helper method for display names
  String _getEventName(NotificationType type) {
    switch (type) {
      case NotificationType.inspectionReminder:
        return 'besiktning';
      case NotificationType.insuranceRenewal:
        return 'försäkringsförnyelse';
      case NotificationType.serviceReminder:
        return 'service';
      case NotificationType.maintenanceDue:
        return 'underhåll förfaller';
      case NotificationType.fuelReminder:
        return 'bränslepåfyllning';
    }
  }

  Future<void> _showPendingNotifications() async {
    final pending = await _service.getPending();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schemalagda notifikationer (${pending.length})'),
        content: pending.isEmpty
            ? const Text('Inga schemalagda notifikationer')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pending.length,
                  itemBuilder: (context, index) {
                    final notif = pending[index];
                    return Card(
                      child: ListTile(
                        title: Text(notif.title ?? 'Notifikation'),
                        //subtitle: Text(notif.body ?? ''),
                        trailing: Text('ID: ${notif.id}'),
                      ),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Stäng'),
          ),
        ],
      ),
    );
  }
}
