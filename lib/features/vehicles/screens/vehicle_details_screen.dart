import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/media/pdf_export_helper.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../../../shared/screens/tabs/vehicle_besiktning_tab.dart';
import '../../../shared/screens/tabs/vehicle_service_tab.dart';
import '../../../shared/screens/tabs/vehicle_receipts_tab.dart';
import '../../maintenance/screens/add_maintenance_screen.dart';
import '../../receipts/screens/add_receipt_screen.dart';

class VehicleDetailsScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const VehicleDetailsScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<VehicleDetailsScreen> createState() =>
      _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends ConsumerState<VehicleDetailsScreen> {
  int _selectedIndex = 0; // Start on first tab

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehiclesProvider);

    // Try to find the vehicle
    final vehicleIndex = vehicles.indexWhere((v) => v.id == widget.vehicleId);

    // If vehicle doesn't exist (was deleted), close this screen
    if (vehicleIndex == -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.pop(context);
        }
      });

      // Return empty scaffold while closing
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final vehicle = vehicles[vehicleIndex];

    // Define the pages
    final pages = [
      VehicleBesiktningTab(vehicle: vehicle),
      VehicleServiceTab(vehicle: vehicle),
      VehicleReceiptsTab(vehicle: vehicle),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          children: [
            Text(
              vehicle.registrationNumber,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${vehicle.make} ${vehicle.model}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportera rapport',
            onPressed: () {
              PdfExportHelper.exportVehiclePDF(
                context: context,
                ref: ref,
                vehicle: vehicle,
              );
            },
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        indicatorColor: Colors.transparent,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event, color: Colors.blue),
            label: 'Besiktning',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build, color: Colors.blue),
            label: 'Service',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: Colors.blue),
            label: 'Kvitton',
          ),
        ],
      ),
      floatingActionButton: _buildContextAwareFAB(vehicle),
    );
  }

  /// Build FAB based on selected tab
  Widget _buildContextAwareFAB(Vehicle vehicle) {
    switch (_selectedIndex) {
      case 1: // Service tab
        return FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AddMaintenanceScreen(vehicleId: vehicle.id),
              ),
            );
          },
          tooltip: 'Lägg till service',
          child: const Icon(Icons.add),
        );

      case 2: // Receipts tab
        return FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddReceiptScreen(vehicleId: vehicle.id),
              ),
            );
          },
          tooltip: 'Lägg till kvitto',
          child: const Icon(Icons.add),
        );

      default:
        return const SizedBox.shrink(); // Hide FAB on Besiktning tab
    }
  }
}
