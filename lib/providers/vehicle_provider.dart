import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';
import '../repositories/vehicle_repository.dart';

// Provider for the vehicle repository
final vehicleRepositoryProvider = Provider((ref) => VehicleRepository());

// Provider for vehicles list
final vehiclesProvider = NotifierProvider<VehiclesNotifier, List<Vehicle>>(
  VehiclesNotifier.new,
);

class VehiclesNotifier extends Notifier<List<Vehicle>> {
  late VehicleRepository _repository;

  @override
  List<Vehicle> build() {
    _repository = ref.read(vehicleRepositoryProvider);
    return _repository.getAll();
  }

  /// Add a new vehicle
  Future<void> addVehicle(Vehicle vehicle) async {
    await _repository.add(vehicle);
    state = _repository.getAll();
  }

  /// Update existing vehicle
  Future<void> updateVehicle(Vehicle vehicle) async {
    await _repository.update(vehicle);
    state = _repository.getAll();
  }

  /// Delete vehicle
  Future<void> deleteVehicle(String vehicleId) async {
    await _repository.delete(vehicleId);
    state = _repository.getAll();
  }

  /// Refresh vehicles from local storage
  void refresh() {
    state = _repository.getAll();
  }

  /// Sync pending changes to cloud
  Future<int> syncPending() async {
    final count = await _repository.syncPending();
    state = _repository.getAll(); // Refresh after sync
    return count;
  }

  /// Pull vehicles from cloud
  Future<void> pullFromCloud() async {
    await _repository.pullFromCloud();
    state = _repository.getAll(); // Refresh after pull
  }

  /// Full sync (pull then push)
  Future<void> fullSync() async {
    await pullFromCloud();
    await syncPending();
  }

  /// Get count of vehicles needing sync
  int get pendingSyncCount => _repository.getPendingSyncCount();

  /// Assign user ID to all vehicles (for migration when user signs in)
  Future<void> assignUserToAllVehicles(String userId) async {
    await _repository.assignUserToAllVehicles(userId);
    state = _repository.getAll();
  }
}
