import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';
import '../services/storage_service.dart';

// Provider that watches vehicles and auto-updates
final vehiclesProvider = StateNotifierProvider<VehicleNotifier, List<Vehicle>>(
  (ref) => VehicleNotifier(),
);

class VehicleNotifier extends StateNotifier<List<Vehicle>> {
  VehicleNotifier() : super([]) {
    loadVehicles();
  }

  void loadVehicles() {
    state = StorageService.getAllVehicles();
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    await StorageService.saveVehicle(vehicle);
    loadVehicles();
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await StorageService.saveVehicle(vehicle);
    loadVehicles();
  }

  Future<void> deleteVehicle(String id) async {
    await StorageService.deleteVehicle(id);
    loadVehicles();
  }

  Vehicle? getVehicle(String id) {
    return StorageService.getVehicle(id);
  }
}
