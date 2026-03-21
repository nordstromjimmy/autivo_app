import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';
import '../repositories/vehicle_repository.dart';
import '../../maintenance/providers/maintenance_provider.dart';
import '../../../core/services/notifications/notification_scheduler.dart';

// Provider for the vehicle repository
final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final notificationScheduler = ref.watch(notificationSchedulerProvider);
  return VehicleRepository(notificationScheduler: notificationScheduler);
});

// Provider for vehicles list (read-only)
final vehiclesProvider = Provider<List<Vehicle>>((ref) {
  // Watch the notifier so this updates when vehicles change
  return ref.watch(vehiclesNotifierProvider);
});

// NotifierProvider for VehiclesNotifier
final vehiclesNotifierProvider =
    NotifierProvider<VehiclesNotifier, List<Vehicle>>(VehiclesNotifier.new);

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
    ref.invalidate(pendingSyncCountProvider);
  }

  /// Update existing vehicle
  Future<void> updateVehicle(Vehicle vehicle) async {
    await _repository.update(vehicle);
    state = _repository.getAll();
    ref.invalidate(pendingSyncCountProvider);
  }

  /// Delete vehicle
  Future<bool> deleteVehicle(String vehicleId) async {
    final deleted = await _repository.delete(vehicleId);
    if (deleted) {
      state = _repository.getAll();
      ref.invalidate(pendingSyncCountProvider);
    }
    return deleted;
  }

  /// Refresh vehicles from local storage
  void refresh() {
    state = _repository.getAll();
    ref.invalidate(pendingSyncCountProvider);
  }

  /// Get count of vehicles needing sync
  int get pendingSyncCount => _repository.getPendingSyncCount();

  /// Assign user ID to all vehicles (for migration when user signs in)
  Future<void> assignUserToAllVehicles(String userId) async {
    await _repository.assignUserToAllVehicles(userId);
    state = _repository.getAll();
  }
}
