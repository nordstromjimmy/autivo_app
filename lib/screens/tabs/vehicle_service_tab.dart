import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/maintenance_record.dart';
import '../../providers/maintenance_provider.dart';
import '../../widgets/maintenance_list_item.dart';
import '../add_maintenance_screen.dart';

class VehicleServiceTab extends ConsumerWidget {
  final String vehicleId;

  const VehicleServiceTab({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maintenanceRecords = ref.watch(maintenanceProvider(vehicleId));

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
                color: Colors.black.withOpacity(0.05),
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
                        AddMaintenanceScreen(vehicleId: vehicleId),
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
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddMaintenanceScreen(vehicleId: vehicleId),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Lägg till första service'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceList(
    BuildContext context,
    List<MaintenanceRecord> records,
  ) {
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
              'Servicehistorik',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${records.length} poster',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Records
        ...records.map((record) => MaintenanceListItem(record: record)),
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
      color: Theme.of(context).primaryColor.withOpacity(0.1),
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
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
