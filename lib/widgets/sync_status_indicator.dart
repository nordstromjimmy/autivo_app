import 'package:flutter/material.dart';

/// Shows sync status of an item (vehicle or maintenance record)
/// Displays cloud icons with different states
class SyncStatusIndicator extends StatelessWidget {
  final bool isSynced;
  final bool needsSync;
  final bool hasCloudBackup;
  final double size;

  const SyncStatusIndicator({
    super.key,
    required this.isSynced,
    required this.needsSync,
    required this.hasCloudBackup,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    // Not signed in - no cloud backup
    if (!hasCloudBackup) {
      return Icon(Icons.cloud_off, size: size, color: Colors.grey[400]);
    }

    // Signed in but needs sync
    if (needsSync) {
      return Icon(Icons.cloud_upload, size: size, color: Colors.orange[700]);
    }

    // Synced successfully
    return Icon(Icons.cloud_done, size: size, color: Colors.green[600]);
  }
}

/// Tooltip explanation for sync status
class SyncStatusTooltip extends StatelessWidget {
  final bool isSynced;
  final bool needsSync;
  final bool hasCloudBackup;
  final Widget child;

  const SyncStatusTooltip({
    super.key,
    required this.isSynced,
    required this.needsSync,
    required this.hasCloudBackup,
    required this.child,
  });

  String get _tooltipMessage {
    if (!hasCloudBackup) {
      return 'Ej synkroniserad - logga in för molnbackup';
    }
    if (needsSync) {
      return 'Väntar på synkronisering';
    }
    return 'Synkroniserad till molnet';
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(message: _tooltipMessage, child: child);
  }
}

/// Combined widget with icon and tooltip
class SyncStatusBadge extends StatelessWidget {
  final bool isSynced;
  final bool needsSync;
  final bool hasCloudBackup;
  final double size;

  const SyncStatusBadge({
    super.key,
    required this.isSynced,
    required this.needsSync,
    required this.hasCloudBackup,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return SyncStatusTooltip(
      isSynced: isSynced,
      needsSync: needsSync,
      hasCloudBackup: hasCloudBackup,
      child: SyncStatusIndicator(
        isSynced: isSynced,
        needsSync: needsSync,
        hasCloudBackup: hasCloudBackup,
        size: size,
      ),
    );
  }
}
