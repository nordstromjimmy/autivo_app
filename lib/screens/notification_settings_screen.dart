import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/notifications/notification_service.dart';
import '../core/services/notifications/notification_types.dart';
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

    final notifStatus = await Permission.notification.status;

    setState(() {
      _permissionsGranted = notifStatus.isGranted;
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

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    NotificationType.inspectionReminder.icon,
                    size: 24,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        NotificationType.inspectionReminder.channelName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '30 dagar innan',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
