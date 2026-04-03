import 'package:supabase_flutter/supabase_flutter.dart';

/// Checks whether a user is within their storage quota before uploading.
///
/// Limits are fetched from the `app_config` table in Supabase, so they
/// can be adjusted in the dashboard without an app update.
///
/// Usage in storage_service.dart before any upload:
/// ```dart
/// final check = await StorageLimitService().checkCanUpload(
///   isPremium: isPremium,
///   fileSizeMb: fileSizeBytes / 1048576,
/// );
/// if (!check.allowed) throw StorageLimitException(check.reason);
/// ```
class StorageLimitService {
  final _supabase = Supabase.instance.client;

  /// Fetch the storage limit for free or premium users from app_config (in MB)
  Future<double> _fetchLimitMb(bool isPremium) async {
    final key = isPremium
        ? 'storage_limit_premium_mb'
        : 'storage_limit_free_mb';

    final response = await _supabase
        .from('app_config')
        .select('value')
        .eq('key', key)
        .single();

    return double.parse(response['value'] as String);
  }

  /// Fetch the calling user's current storage usage in MB via Supabase function
  Future<double> _fetchUsageMb() async {
    final response = await _supabase.rpc('get_user_storage_usage_mb');
    return (response as num).toDouble();
  }

  /// Check whether the user can upload a file of the given size.
  ///
  /// [isPremium] — pass your existing premium check result
  /// [fileSizeMb] — size of the file about to be uploaded, in MB
  Future<StorageLimitCheck> checkCanUpload({
    required bool isPremium,
    required double fileSizeMb,
  }) async {
    try {
      final limitMb = await _fetchLimitMb(isPremium);
      final usageMb = await _fetchUsageMb();
      final projectedMb = usageMb + fileSizeMb;

      if (projectedMb > limitMb) {
        final usedFormatted = usageMb.toStringAsFixed(0);
        final limitFormatted = limitMb.toStringAsFixed(0);
        return StorageLimitCheck(
          allowed: false,
          usageMb: usageMb,
          limitMb: limitMb,
          reason: isPremium
              ? 'Du har nått din lagringsgräns ($usedFormatted/$limitFormatted MB). '
                    'Kontakta support för att utöka ditt utrymme.'
              : 'Du har nått din lagringsgräns ($usedFormatted/$limitFormatted MB). '
                    'Uppgradera till Premium för mer utrymme.',
        );
      }

      return StorageLimitCheck(
        allowed: true,
        usageMb: usageMb,
        limitMb: limitMb,
      );
    } catch (e) {
      // If the check fails (e.g. offline), allow the upload rather than
      // blocking the user on a network error.
      return StorageLimitCheck(allowed: true, usageMb: 0, limitMb: 0);
    }
  }
}

class StorageLimitCheck {
  final bool allowed;
  final double usageMb;
  final double limitMb;
  final String? reason;

  StorageLimitCheck({
    required this.allowed,
    required this.usageMb,
    required this.limitMb,
    this.reason,
  });
}

class StorageLimitException implements Exception {
  final String message;
  StorageLimitException(this.message);

  @override
  String toString() => message;
}
