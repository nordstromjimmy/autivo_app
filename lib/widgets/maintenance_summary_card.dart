import 'package:flutter/material.dart';
import '../models/maintenance_record.dart';

Widget buildSummaryStats(
  BuildContext context,
  List<MaintenanceRecord> records,
) {
  final totalCost = records
      .where((r) => r.cost != null)
      .fold<double>(0, (sum, r) => sum + r.cost!);

  final thisYearRecords = records
      .where((r) => r.date.year == DateTime.now().year)
      .toList();

  final thisYearCost = thisYearRecords
      .where((r) => r.cost != null)
      .fold<double>(0, (sum, r) => sum + r.cost!);

  return Card(
    margin: const EdgeInsets.all(16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sammanfattning',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                'Totalt',
                '${records.length}',
                'poster',
                Icons.list,
              ),
              _buildStatItem(
                context,
                'Total kostnad',
                '${totalCost.toStringAsFixed(0)} kr',
                'alla tider',
                Icons.account_balance_wallet,
              ),
              _buildStatItem(
                context,
                'I år',
                '${thisYearCost.toStringAsFixed(0)} kr',
                '${thisYearRecords.length} poster',
                Icons.calendar_today,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildStatItem(
  BuildContext context,
  String label,
  String value,
  String subtitle,
  IconData icon,
) {
  return Column(
    children: [
      Icon(icon, color: Theme.of(context).primaryColor, size: 24),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
    ],
  );
}
