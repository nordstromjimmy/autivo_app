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
              icon: const Icon(Icons.add),
              label: const Text('Lägg till service'),
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
        // Summary card
        _buildSummaryCard(context, records),

        const SizedBox(height: 16),

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
                    vehicleName:
                        '${vehicle.make} ${vehicle.model} (${vehicle.registrationNumber})',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.list),
            label: Text('Visa alla'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    List<MaintenanceRecord> records,
  ) {
    final totalCost = records
        .where((r) => r.cost != null)
        .fold<double>(0, (sum, r) => sum + r.cost!);

    final serviceCount = records.where((r) => r.type == 'service').length;
    final partsCount = records.where((r) => r.type == 'parts').length;

    return Card(
      color: Theme.of(context).primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat(
                  context,
                  icon: Icons.build,
                  label: 'Service',
                  value: '$serviceCount',
                ),
                Container(height: 40, width: 1, color: Colors.grey[300]),
                _buildSummaryStat(
                  context,
                  icon: Icons.settings,
                  label: 'Reservdelar',
                  value: '$partsCount',
                ),
                Container(height: 40, width: 1, color: Colors.grey[300]),
                _buildSummaryStat(
                  context,
                  icon: Icons.attach_money,
                  label: 'Totalt',
                  value: '${totalCost.toStringAsFixed(0)} kr',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ],
    );
  }
}
