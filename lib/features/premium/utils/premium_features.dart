import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/combined_premium_provider.dart';
import '../providers/purchase_provider.dart';

/// Helper class to check if specific premium features are available
class PremiumFeatures {
  final Ref ref;

  PremiumFeatures(this.ref);

  // === CORE CHECKS ===

  /// Check if user has an active account (logged into Supabase)
  /// NOW REACTIVE - watches currentUserProvider
  bool get hasAccount {
    final user = ref.watch(
      currentUserProvider,
    ); // Watch provider, not direct read!
    return user != null;
  }

  /// Check if user has premium from RevenueCat (sync - uses cached state)
  bool get hasPremiumFromRevenueCat {
    final premiumAsyncValue = ref.read(premiumStatusProvider);
    return premiumAsyncValue.maybeWhen(
      data: (isPremium) => isPremium,
      orElse: () => false,
    );
  }

  /// Check if user has premium from Supabase users table (manual grant)
  /// This is now synchronous and uses a cached provider
  bool get hasPremiumFromSupabase {
    final supabasePremiumAsyncValue = ref.read(supabasePremiumStatusProvider);
    return supabasePremiumAsyncValue.maybeWhen(
      data: (isPremium) => isPremium,
      orElse: () => false,
    );
  }

  /// Check if user has premium (from EITHER RevenueCat OR Supabase)
  /// This allows both purchases AND manual grants to work
  bool get hasPremium {
    return hasPremiumFromRevenueCat || hasPremiumFromSupabase;
  }

  /// Check if user has both account AND premium (sync for quick checks)
  bool get hasAccountAndPremium {
    if (!hasAccount) return false;
    return hasPremium;
  }

  // === FEATURE-SPECIFIC CHECKS ===

  /// Cloud sync - requires account AND premium
  bool get canUseCloudSync {
    return hasAccountAndPremium;
  }

  /// OCR verification - requires premium (and account for cloud storage)
  bool get canUseOCRVerification {
    return hasAccountAndPremium;
  }

  /// Receipt photos - requires premium (and account for cloud storage)
  bool get canUseReceiptPhotos {
    return hasAccountAndPremium;
  }

  /// Professional PDF export (no watermark) - requires premium
  bool get canUseProfessionalPDF {
    return hasPremium;
  }

  /// Cost analytics - requires premium
  bool get canUseCostAnalytics {
    return hasPremium;
  }

  /// Excel export - requires premium
  bool get canUseExcelExport {
    return hasPremium;
  }

  /// Check if can add more vehicles (checks both limit and premium)
  bool canAddVehicle(int currentVehicleCount) {
    if (hasPremium) {
      return true; // Unlimited vehicles
    } else {
      return currentVehicleCount < 1; // Free tier: 1 vehicle max
    }
  }

  // === PREMIUM MANAGEMENT ===

  /// Sync premium status from RevenueCat to Supabase users table
  /// SMART SYNC: Only overwrites if RevenueCat has premium or Supabase source is 'revenuecat'
  /// This prevents manual grants from being overwritten
  Future<void> syncPremiumToSupabase() async {
    if (!hasAccount) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final isPremiumFromRC = hasPremiumFromRevenueCat;

    try {
      // First, check current Supabase status
      final response = await Supabase.instance.client
          .from('users')
          .select('is_premium, premium_source')
          .eq('id', user.id)
          .maybeSingle();

      final currentSupabasePremium = response?['is_premium'] as bool? ?? false;
      final currentSource = response?['premium_source'] as String?;

      // SMART SYNC LOGIC:
      // 1. If RevenueCat has premium → always update Supabase
      // 2. If Supabase has premium from 'manual' source → DON'T overwrite
      // 3. If Supabase source is 'revenuecat' → update from RevenueCat

      final shouldSync =
          isPremiumFromRC || // RevenueCat has premium, sync it
          currentSource ==
              'revenuecat'; // Only overwrite RevenueCat-sourced premium

      if (!shouldSync && currentSupabasePremium) {
        // Supabase has manual premium, don't overwrite
        return;
      }

      // Update users table
      await Supabase.instance.client
          .from('users')
          .update({
            'is_premium': isPremiumFromRC,
            'premium_source': isPremiumFromRC ? 'revenuecat' : null,
            'premium_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      // Refresh the Supabase premium status provider
      ref.invalidate(supabasePremiumStatusProvider);
    } catch (e) {
      print('❌ Error syncing premium to Supabase: $e');
    }
  }

  /// Manually set premium status in Supabase users table (admin/testing only)
  /// This is for manual grants, not purchases
  Future<void> setSupabasePremium(bool isPremium) async {
    if (!hasAccount) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      // Update users table
      await Supabase.instance.client
          .from('users')
          .update({
            'is_premium': isPremium,
            'premium_source': 'manual',
            'premium_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      // Refresh the providers
      ref.invalidate(supabasePremiumStatusProvider);
      ref.invalidate(premiumStatusProvider);
    } catch (e) {
      print('❌ Error setting Supabase premium: $e');
    }
  }

  // === FEATURE DESCRIPTIONS ===

  /// Get list of premium features for display
  static List<PremiumFeature> get allFeatures => [
    PremiumFeature(
      name: 'Obegränsat antal fordon',
      description: 'Hantera hur många bilar du vill',
      requiresAccount: false,
    ),
    PremiumFeature(
      name: 'Molnsynkronisering',
      description: 'Säkerhetskopiera automatiskt till molnet',
      requiresAccount: true,
    ),
    PremiumFeature(
      name: 'OCR-verifiering',
      description: 'Verifiera fordon med registreringsbevis',
      requiresAccount: true,
    ),
    PremiumFeature(
      name: 'Professionella PDF-exporter',
      description: 'Exportera utan vattenstämpel',
      requiresAccount: false,
    ),
    PremiumFeature(
      name: 'Kostnadsanalys',
      description: 'Detaljerad statistik och trender',
      requiresAccount: false,
    ),
    PremiumFeature(
      name: 'Kvittofoton',
      description: 'Bifoga kvitton och dokument',
      requiresAccount: true,
    ),
    PremiumFeature(
      name: 'Excel-export',
      description: 'Exportera data till Excel/CSV',
      requiresAccount: false,
    ),
    PremiumFeature(
      name: 'Prioriterad support',
      description: 'Få hjälp snabbare via e-post',
      requiresAccount: false,
    ),
  ];
}

/// Model for a premium feature
class PremiumFeature {
  final String name;
  final String description;
  final bool requiresAccount;

  PremiumFeature({
    required this.name,
    required this.description,
    required this.requiresAccount,
  });
}

/// Provider to access PremiumFeatures helper
/// NOW REACTIVE - watches auth state changes
final premiumFeaturesProvider = Provider<PremiumFeatures>((ref) {
  // Watch auth state so this rebuilds when user logs in/out
  ref.watch(currentUserProvider);
  return PremiumFeatures(ref);
});
