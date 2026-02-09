import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/maintenance_record.dart';
import '../providers/maintenance_provider.dart';
import '../screens/add_maintenance_screen.dart';

class MaintenanceListItem extends ConsumerWidget {
  final MaintenanceRecord record;

  const MaintenanceListItem({super.key, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(record.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(context);
      },
      onDismissed: (direction) {
        // Capture the notifier and record before potential disposal
        final notifier = ref.read(maintenanceNotifierProvider.notifier);
        final deletedRecord = record;

        notifier.deleteRecord(record.id);

        // Clear any existing snackbars first
        ScaffoldMessenger.of(context).clearSnackBars();

        final messenger = ScaffoldMessenger.of(context);
        bool actionClicked = false;

        messenger.showSnackBar(
          SnackBar(
            content: const Text('Post borttagen'),
            // Remove duration - we'll handle it manually
            action: SnackBarAction(
              label: 'Ångra',
              onPressed: () {
                actionClicked = true;
                // Re-add the record
                notifier.addRecord(deletedRecord);

                // Immediately remove the snackbar
                messenger.removeCurrentSnackBar();
              },
            ),
          ),
        );

        // Manually dismiss after 3 seconds if action wasn't clicked
        Future.delayed(const Duration(seconds: 3), () {
          if (!actionClicked) {
            messenger.removeCurrentSnackBar();
          }
        });
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text(
              'Ta bort',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () {
            // Clear snackbars before navigating to edit
            ScaffoldMessenger.of(context).clearSnackBars();

            // Navigate to edit screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddMaintenanceScreen(
                  vehicleId: record.vehicleId,
                  existingRecord: record,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon
                CircleAvatar(
                  backgroundColor: _getTypeColor(
                    record.type,
                  ).withValues(alpha: 0.2),
                  child: Icon(
                    _getTypeIcon(record.type),
                    color: _getTypeColor(record.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(record.date),
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      if (record.mileage != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${record.mileage} km',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (record.location != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                record.location!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Cost and arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (record.cost != null)
                      Text(
                        '${record.cost!.toStringAsFixed(0)} kr',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ta bort post?'),
        content: Text('Vill du ta bort "${record.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ta bort'),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'service':
        return Icons.build;
      case 'parts':
        return Icons.settings;
      case 'besiktning':
        return Icons.verified;
      case 'tire_change':
        return Icons.album;
      default:
        return Icons.description;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'service':
        return Colors.blue;
      case 'parts':
        return Colors.orange;
      case 'besiktning':
        return Colors.green;
      case 'tire_change':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.year}';
  }
}
