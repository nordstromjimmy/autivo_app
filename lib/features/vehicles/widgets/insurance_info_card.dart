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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: Colors.green[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Försäkring',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (hasInsurance && vehicle.insuranceCompany != null)
                          Text(
                            vehicle.insuranceCompany!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_outlined, color: Colors.grey[400], size: 20),
                ],
              ),

              if (!hasInsurance) ...[
                const SizedBox(height: 12),
                Text(
                  'Ingen försäkringsinformation tillagd',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tryck för att lägga till',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ] else ...[
                const SizedBox(height: 16),

                // Insurance details
                _buildInfoRow(context, 'Typ', vehicle.insuranceTypeDisplay),

                if (vehicle.insuranceCostPerYear != null)
                  _buildInfoRow(
                    context,
                    'Kostnad/år',
                    '${vehicle.insuranceCostPerYear!.toStringAsFixed(0)} kr',
                  ),

                if (vehicle.insuranceRenewalDate != null)
                  _buildInfoRow(
                    context,
                    'Förnyelsedatum',
                    DateFormat(
                      'd MMM yyyy',
                      'sv',
                    ).format(vehicle.insuranceRenewalDate!),
                    isWarning: _isRenewalSoon(vehicle.insuranceRenewalDate!),
                  ),

                if (vehicle.insurancePolicyNumber != null)
                  _buildInfoRow(
                    context,
                    'Försäkringsnummer',
                    vehicle.insurancePolicyNumber!,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool isWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const SizedBox(width: 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isWarning ? Colors.orange[700] : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isRenewalSoon(DateTime renewalDate) {
    final now = DateTime.now();
    final daysUntilRenewal = renewalDate.difference(now).inDays;
    return daysUntilRenewal <= 30 && daysUntilRenewal >= 0;
  }
}
