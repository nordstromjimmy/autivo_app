import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../screens/edit_insurance_screen.dart';

class InsuranceInfoCard extends StatelessWidget {
  final Vehicle vehicle;

  const InsuranceInfoCard({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final hasInsurance = vehicle.insuranceCompany != null;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditInsuranceScreen(vehicle: vehicle),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: Colors.green[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasInsurance ? vehicle.insuranceCompany! : 'Försäkring',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.edit_outlined, color: Colors.grey[400], size: 18),
                ],
              ),

              if (!hasInsurance) ...[
                const SizedBox(height: 8),
                Text(
                  'Tryck för att lägga till försäkringsinformation',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _buildChip(context, vehicle.insuranceTypeDisplay),
                    if (vehicle.insuranceCostPerYear != null)
                      _buildChip(
                        context,
                        '${vehicle.insuranceCostPerYear!.toStringAsFixed(0)} kr/år',
                      ),
                    if (vehicle.insurancePolicyNumber != null)
                      _buildChip(context, vehicle.insurancePolicyNumber!),
                    if (vehicle.insuranceRenewalDate != null)
                      _buildChip(
                        context,
                        'Förnyas ${DateFormat('d MMM yyyy', 'sv').format(vehicle.insuranceRenewalDate!)}',
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label) {
    return Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600]));
  }
}
