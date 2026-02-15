import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            // Tab views
            Expanded(
              child: TabBarView(
                children: [
                  VehicleBesiktningTab(vehicle: vehicle),
                  VehicleServiceTab(vehicle: vehicle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
