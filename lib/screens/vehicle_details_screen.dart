import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vehicle_provider.dart';
import 'tabs/vehicle_besiktning_tab.dart';
import 'tabs/vehicle_service_tab.dart';

class VehicleDetailsScreen extends ConsumerWidget {
  final String vehicleId;

  const VehicleDetailsScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider);

    // Try to find the vehicle
    final vehicleIndex = vehicles.indexWhere((v) => v.id == vehicleId);

    // If vehicle doesn't exist (was deleted), close this screen
    if (vehicleIndex == -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Fordon borttaget')));
        }
      });

      // Return empty scaffold while closing
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final vehicle = vehicles[vehicleIndex];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(vehicle.registrationNumber),
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
