import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/vehicles/models/vehicle.dart';
import '../../../features/maintenance/models/maintenance_record.dart';
import '../../config/supabase_config.dart';

class SyncService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Table names in Supabase
  static const String vehiclesTable = 'vehicles';
  static const String maintenanceTable = 'maintenance_records';

  // ==================== VEHICLES ====================

  /// Upload a vehicle to Supabase
  Future<String?> uploadVehicle(Vehicle vehicle) async {
    try {
      final data = {
        'id': vehicle.id,
        'user_id': SupabaseConfig.currentUserId,
        'registration_number': vehicle.registrationNumber,
        'make': vehicle.make,
        'model': vehicle.model,
        'year': vehicle.year,
        'fuel_type': vehicle.fuelType,
        'engine_size': vehicle.engineSize,
        'next_besiktning_date': vehicle.nextBesiktningDate?.toIso8601String(),
        'current_mileage': vehicle.currentMileage,
        'ownership_start_date': vehicle.ownershipStartDate?.toIso8601String(),
        'verification_level': vehicle.verificationLevel,
        'verified_at': vehicle.verifiedAt?.toIso8601String(),
        'verification_proof': vehicle.verificationProof,
        'verification_confidence': vehicle.verificationConfidence,
        'created_at': vehicle.createdAt.toIso8601String(),
        'updated_at': vehicle.updatedAt.toIso8601String(),
      };

      final response = await _client
          .from(vehiclesTable)
          .upsert(data)
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      print('Error uploading vehicle: $e');
      return null;
    }
  }

  /// Download all vehicles for current user
  Future<List<Map<String, dynamic>>> downloadVehicles() async {
    try {
      final response = await _client
          .from(vehiclesTable)
          .select()
          .eq('user_id', SupabaseConfig.currentUserId!)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error downloading vehicles: $e');
      return [];
    }
  }

  /// Delete vehicle from Supabase
  Future<bool> deleteVehicle(String vehicleId) async {
    try {
      await _client.from(vehiclesTable).delete().eq('id', vehicleId);
      return true;
    } catch (e) {
      print('Error deleting vehicle: $e');
      return false;
    }
  }

  // ==================== MAINTENANCE RECORDS ====================

  /// Upload a maintenance record to Supabase
  Future<String?> uploadMaintenanceRecord(MaintenanceRecord record) async {
    try {
      final data = {
        'id': record.id,
        'user_id': SupabaseConfig.currentUserId,
        'vehicle_id': record.vehicleId,
        'date': record.date.toIso8601String(),
        'type': record.type,
        'description': record.description,
        'mileage': record.mileage,
        'cost': record.cost,
        'location': record.location,
        'created_at': record.createdAt.toIso8601String(),
        'updated_at': record.updatedAt.toIso8601String(),
      };

      final response = await _client
          .from(maintenanceTable)
          .upsert(data)
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      print('Error uploading maintenance record: $e');
      return null;
    }
  }

  /// Download all maintenance records for a vehicle
  Future<List<Map<String, dynamic>>> downloadMaintenanceRecords(
    String vehicleId,
  ) async {
    try {
      final response = await _client
          .from(maintenanceTable)
          .select()
          .eq('vehicle_id', vehicleId)
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error downloading maintenance records: $e');
      return [];
    }
  }

  /// Delete maintenance record from Supabase
  Future<bool> deleteMaintenanceRecord(String recordId) async {
    try {
      await _client.from(maintenanceTable).delete().eq('id', recordId);
      return true;
    } catch (e) {
      print('Error deleting maintenance record: $e');
      return false;
    }
  }

  // ==================== SYNC HELPERS ====================

  /// Check if online and can sync
  Future<bool> canSync() async {
    try {
      // Simple ping to check connectivity
      await _client.from(vehiclesTable).select('id').limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get count of items needing sync
  Future<int> getPendingSyncCount() async {
    // This will be implemented in the repository layer
    // For now, just return 0
    return 0;
  }
}
