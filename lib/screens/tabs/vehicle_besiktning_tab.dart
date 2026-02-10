import 'package:flutter/material.dart';
import '../../models/vehicle.dart';
import '../besiktning_checklist_screen.dart';

class VehicleBesiktningTab extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleBesiktningTab({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Besiktning status card
          _buildBesiktningCard(context),

          const SizedBox(height: 16),

          // Quick actions
          _buildQuickActions(context),

          const SizedBox(height: 16),

          // Info section
          _buildInfoSection(context),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBesiktningCard(BuildContext context) {
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

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Förberedelser',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Checklist button
        _buildActionCard(
          context,
          icon: Icons.checklist,
          title: 'Checklista',
          description: 'Kontrollera din bil innan besiktning',
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BesiktningChecklistScreen(vehicle: vehicle),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        // Common failures button
        _buildActionCard(
          context,
          icon: Icons.warning_amber,
          title: 'Vanliga fel',
          description:
              'Se vad som ofta går fel på ${vehicle.make} ${vehicle.model}',
          color: Colors.orange,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vanliga fel - kommer snart')),
            );
          },
        ),

        const SizedBox(height: 8),

        // Find station button
        _buildActionCard(
          context,
          icon: Icons.location_on,
          title: 'Hitta besiktningsstation',
          description: 'Boka tid på närmaste station',
          color: Colors.green,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Hitta station - kommer snart')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Besiktningsinformation',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Första besiktning', '3 år efter registrering'),
            _buildInfoRow('Därefter', 'Var 14:e månad'),
            _buildInfoRow('Efterkontroll', 'Inom 2 månader vid underkänt'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
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
