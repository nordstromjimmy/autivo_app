import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/maintenance_record.dart';
import '../../models/vehicle.dart';
import '../../providers/maintenance_provider.dart';
import '../../widgets/maintenance_list_item.dart';
import '../add_maintenance_screen.dart';
import '../maintenance_history_screen.dart';

class VehicleServiceTab extends ConsumerWidget {
  final Vehicle vehicle;

  const VehicleServiceTab({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenanceRecords = ref.watch(maintenanceProvider(vehicle.id));

    return Column(
      children: [
        // Maintenance history
        Expanded(
          child: maintenanceRecords.isEmpty
              ? _buildEmptyState(context)
              : _buildMaintenanceList(context, maintenanceRecords),
        ),

        // Add service button at bottom
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddMaintenanceScreen(vehicleId: vehicle.id),
                  ),
                );
              },
              label: const Text('Lägg till'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Ingen servicehistorik än',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Lägg till service och underhåll för att hålla koll på din bil',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceList(
    BuildContext context,
    List<MaintenanceRecord> records,
  ) {
    // Show only last 5 records
    final displayRecords = records.take(5).toList();
    final hasMore = records.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Records list header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Senaste',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              hasMore ? '${records.length} totalt' : '${records.length} poster',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Show only 5 records
        ...displayRecords.map((record) => MaintenanceListItem(record: record)),

        // "View all" button if more records exist
        if (hasMore) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MaintenanceHistoryScreen(
                    vehicleId: vehicle.id,
                    vehicleName: '${vehicle.make} ${vehicle.model}',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.list),
            label: Text('Visa alla'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ],
    );
  }
}
