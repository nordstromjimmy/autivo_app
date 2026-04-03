import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../screens/add_vehicle_screen.dart';
import '../../inspection/screens/vehicle_verification_screen.dart';

class VehicleInfoCard extends StatelessWidget {
  final Vehicle vehicle;

  const VehicleInfoCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            vehicle.registrationNumber,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (vehicle.isVerified) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.verified, size: 20, color: Colors.green),
                          ],
                          Spacer(),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddVehicleScreen(
                                    existingVehicle: vehicle,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                      Text(
                        '${vehicle.make} ${vehicle.model}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Verification section
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          VehicleVerificationScreen(vehicle: vehicle),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(
                  12,
                ), // Slightly more rounded
                child: Ink(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      width: 1.5,
                      color: vehicle.isVerified
                          ? Colors.green.withValues(alpha: 0.2)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicle.isVerified
                                    ? 'Verifierad'
                                    : 'Ej verifierad',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: vehicle.isVerified
                                      ? Colors.green
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                vehicle.isVerified
                                    ? vehicle.verificationBadge
                                    : 'Tryck för att verifiera ägarskap',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn('År', vehicle.year.toString()),
                if (vehicle.fuelType != null)
                  _buildInfoColumn('Bränsle', vehicle.fuelType!),
                if (vehicle.currentMileage != null)
                  _buildInfoColumn('Mätarst.', '${vehicle.currentMileage} km'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ],
    );
  }
}
