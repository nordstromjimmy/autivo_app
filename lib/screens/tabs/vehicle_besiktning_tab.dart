import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/vehicle.dart';
import '../../widgets/action_card.dart';
import '../../widgets/besiktning_status_card.dart';
import '../../widgets/vehicle_info_card.dart';
import '../besiktning_checklist_screen.dart';

class VehicleBesiktningTab extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleBesiktningTab({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle info card
            VehicleInfoCard(vehicle: vehicle),

            const SizedBox(height: 16),

            // Besiktning status card
            BesiktningStatusCard(vehicle: vehicle),

            const SizedBox(height: 16),

            // Quick actions
            _buildQuickActions(context),
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
        ActionCard(
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
        ActionCard(
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
        ActionCard(
          icon: Icons.location_on,
          title: 'Hitta besiktningsstation',
          description: 'Boka tid på närmaste station',
          color: Colors.green,
          onTap: () => _openBesiktningMap(context),
        ),
      ],
    );
  }

  // Open Google Maps with search for car inspection stations
  Future<void> _openBesiktningMap(BuildContext context) async {
    final Uri mapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=Bilbesiktning',
    );

    try {
      if (await canLaunchUrl(mapsUrl)) {
        await launchUrl(mapsUrl, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kunde inte öppna kartan')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ett fel uppstod när kartan skulle öppnas'),
          ),
        );
      }
    }
  }
}
