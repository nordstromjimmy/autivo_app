import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/vehicles/models/vehicle.dart';
import '../../../features/maintenance/models/maintenance_record.dart';
import '../../../features/receipts/models/receipt.dart';

/// Represents an active public share link
class ShareReport {
  final String shareId;
  final String shareUrl;
  final DateTime expiresAt;
  final DateTime createdAt;

  ShareReport({
    required this.shareId,
    required this.shareUrl,
    required this.expiresAt,
    required this.createdAt,
  });

  factory ShareReport.fromMap(Map<String, dynamic> data) {
    final shareId = data['share_id'] as String;
    return ShareReport(
      shareId: shareId,
      shareUrl: 'https://autivo.se/r/$shareId',
      expiresAt: DateTime.parse(data['expires_at'] as String),
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }

  int get daysRemaining =>
      expiresAt.difference(DateTime.now()).inDays.clamp(0, 90);
}

/// Manages creation, retrieval and deletion of public vehicle history links.
/// One active link is allowed per vehicle at a time.
class ShareService {
  final _supabase = Supabase.instance.client;

  static const String _table = 'public_reports';
  static const String _bucket = 'receipts';
  static const int _expiryDays = 90;

  /// Returns the active share link for a vehicle, or null if none exists
  Future<ShareReport?> getShareLink(String vehicleId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from(_table)
          .select()
          .eq('vehicle_id', vehicleId)
          .eq('owner_id', userId)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      if (response == null) return null;
      return ShareReport.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Creates a new share link for a vehicle.
  /// Deletes any existing link for the same vehicle first.
  Future<ShareReport> createShareLink({
    required Vehicle vehicle,
    required List<MaintenanceRecord> records,
    required List<Receipt>? receipts,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Inte inloggad');

    // Remove any existing link for this vehicle
    await _supabase
        .from(_table)
        .delete()
        .eq('vehicle_id', vehicle.id)
        .eq('owner_id', userId);

    // Build receipt data with signed image URLs
    final receiptData = await _buildReceiptData(receipts);

    final shareId = _generateShareId();
    final expiresAt = DateTime.now().add(const Duration(days: _expiryDays));

    final response = await _supabase
        .from(_table)
        .insert({
          'share_id': shareId,
          'vehicle_id': vehicle.id,
          'owner_id': userId,
          'vehicle_snapshot': _buildSnapshot(vehicle, records, receiptData),
          'expires_at': expiresAt.toIso8601String(),
        })
        .select()
        .single();

    return ShareReport.fromMap(response);
  }

  /// Deletes the share link for a vehicle
  Future<void> deleteShareLink(String vehicleId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase
        .from(_table)
        .delete()
        .eq('vehicle_id', vehicleId)
        .eq('owner_id', userId);
  }

  // ==================== HELPERS ====================

  /// Generates signed 90-day image URLs for each receipt
  Future<List<Map<String, dynamic>>> _buildReceiptData(
    List<Receipt>? receipts,
  ) async {
    if (receipts == null || receipts.isEmpty) return [];

    final result = <Map<String, dynamic>>[];

    for (final receipt in receipts) {
      String? imageUrl;

      if (receipt.storagePath.isNotEmpty) {
        try {
          imageUrl = await _supabase.storage
              .from(_bucket)
              .createSignedUrl(
                receipt.storagePath,
                60 * 60 * 24 * _expiryDays, // 90 days in seconds
              );
        } catch (_) {
          // Skip if signing fails — receipt will show without image
        }
      }

      result.add({
        'description': receipt.description,
        'date': receipt.date?.toIso8601String(),
        'amount': receipt.amount,
        'image_url': imageUrl,
      });
    }

    return result;
  }

  Map<String, dynamic> _buildSnapshot(
    Vehicle vehicle,
    List<MaintenanceRecord> records,
    List<Map<String, dynamic>> receiptData,
  ) {
    return {
      'vehicle': {
        'registration_number': vehicle.registrationNumber,
        'make': vehicle.make,
        'model': vehicle.model,
        'year': vehicle.year,
        'fuel_type': vehicle.fuelType,
        'current_mileage': vehicle.currentMileage,
        'ownership_start_date': vehicle.ownershipStartDate?.toIso8601String(),
        'next_besiktning_date': vehicle.nextBesiktningDate?.toIso8601String(),
        'is_verified': vehicle.isVerified,
        'verification_badge': vehicle.verificationBadgePdf,
      },
      'records': records
          .map(
            (r) => {
              'date': r.date.toIso8601String(),
              'type': r.type,
              'description': r.description,
              'location': r.location,
              'mileage': r.mileage,
              'cost': r.cost,
            },
          )
          .toList(),
      'receipts': receiptData,
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  String _generateShareId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return List.generate(10, (_) => chars[random.nextInt(chars.length)]).join();
  }
}
