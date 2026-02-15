import 'package:flutter/material.dart';
import '../models/vehicle.dart';

class BesiktningStatusCard extends StatelessWidget {
  final Vehicle vehicle;

  const BesiktningStatusCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final daysUntil = vehicle.daysUntilBesiktning;
    final urgencyColor = _getUrgencyColor(vehicle.urgencyLevel);

    return Card(
      color: urgencyColor.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: urgencyColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Nästa besiktning',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Date and countdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(vehicle.nextBesiktningDate),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[200],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getWeekdayName(vehicle.nextBesiktningDate),
                      style: TextStyle(color: Colors.grey[200]),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: urgencyColor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    children: [
                      Text(
                        daysUntil >= 0 ? '$daysUntil' : '${daysUntil.abs()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                      Text(
                        daysUntil >= 0 ? 'dagar kvar' : 'dagar sen',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Progress bar
            if (daysUntil <= 30 && daysUntil >= 0) ...[
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: 1 - (daysUntil / 30),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(urgencyColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dags att förbereda besiktning!',
                style: TextStyle(
                  fontSize: 12,
                  color: urgencyColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getUrgencyColor(String level) {
    switch (level) {
      case 'overdue':
        return Colors.red;
      case 'critical':
        return Colors.orange;
      case 'warning':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.year}';
  }

  String _getWeekdayName(DateTime date) {
    const weekdays = [
      'Måndag',
      'Tisdag',
      'Onsdag',
      'Torsdag',
      'Fredag',
      'Lördag',
      'Söndag',
    ];
    return weekdays[date.weekday - 1];
  }
}
