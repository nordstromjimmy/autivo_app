import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import 'add_vehicle_screen.dart';
import 'tabs/vehicle_besiktning_tab.dart';
import 'tabs/vehicle_service_tab.dart';

class VehicleDetailsScreen extends ConsumerWidget {
  final String vehicleId;

  const VehicleDetailsScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref
        .watch(vehiclesProvider)
        .firstWhere(
          (v) => v.id == vehicleId,
          orElse: () => throw Exception('Vehicle not found'),
        );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(vehicle.registrationNumber),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddVehicleScreen(existingVehicle: vehicle),
                  ),
                );
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Column(
              children: [
                TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(icon: Icon(Icons.event), text: 'Besiktning'),
                    Tab(icon: Icon(Icons.build), text: 'Service'),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            // Vehicle info card (shared across tabs)
            _buildVehicleInfoCard(context, vehicle),

            // Tab views
            Expanded(
              child: TabBarView(
                children: [
                  VehicleBesiktningTab(vehicle: vehicle),
                  VehicleServiceTab(vehicleId: vehicleId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleInfoCard(BuildContext context, Vehicle vehicle) {
    return Card(
      margin: const EdgeInsets.all(16),
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
                      Text(
                        vehicle.registrationNumber,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
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
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn('År', vehicle.year.toString()),
                if (vehicle.fuelType != null)
                  _buildInfoColumn('Bränsle', vehicle.fuelType!),
                _buildInfoColumn(
                  'Besiktning',
                  '${vehicle.daysUntilBesiktning} dagar',
                ),
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
