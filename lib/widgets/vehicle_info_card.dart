import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../screens/add_vehicle_screen.dart';
import '../screens/vehicle_verification_screen.dart';

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
                  color: Theme.of(context).primaryColor,
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
                            Icon(
                              Icons.verified,
                              size: 20,
                              color: _getVerificationColor(
                                vehicle.verificationLevel,
                              ),
                            ),
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
                            icon: const Icon(Icons.settings),
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
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        VehicleVerificationScreen(vehicle: vehicle),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: vehicle.isVerified
                      ? _getVerificationColor(
                          vehicle.verificationLevel,
                        ).withValues(alpha: 0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: vehicle.isVerified
                        ? _getVerificationColor(
                            vehicle.verificationLevel,
                          ).withValues(alpha: 0.3)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      vehicle.isVerified ? Icons.verified : Icons.verified_user,
                      size: 20,
                      color: vehicle.isVerified
                          ? _getVerificationColor(vehicle.verificationLevel)
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.isVerified ? 'Verifierad' : 'Ej verifierad',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: vehicle.isVerified
                                  ? _getVerificationColor(
                                      vehicle.verificationLevel,
                                    )
                                  : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            vehicle.isVerified
                                ? vehicle.verificationBadge
                                : 'Tryck för att verifiera ägarskap',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Colors.grey[400],
                    ),
                  ],
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

  Color _getVerificationColor(String level) {
    switch (level) {
      case 'self':
        return Colors.orange;
      case 'sms':
        return Colors.blue;
      case 'official':
        return Colors.green;
      default:
        return Colors.grey;
    }
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
