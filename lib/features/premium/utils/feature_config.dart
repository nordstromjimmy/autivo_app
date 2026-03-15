import 'feature_gates.dart';

/// Central configuration for what each tier can do
///
/// ⚠️ SINGLE SOURCE OF TRUTH ⚠️
/// Change tier restrictions HERE and ONLY here!
///
/// To modify what users can do:
/// 1. Find the tier (unregistered/free/premium)
/// 2. Add or remove features from the set
/// 3. Changes apply everywhere automatically!
class FeatureConfig {
  /// Define what each tier has access to
  static const Map<UserTier, Set<AppFeature>> tierFeatures = {
    // ==================== UNREGISTERED ====================
    // No account - local only, very limited
    // Can use the app but no cloud features, limited to 1 vehicle
    UserTier.unregistered: {
      AppFeature.addVehicle, // Can add vehicles (up to limit)
      AppFeature.editVehicle, // Can edit vehicles
      AppFeature.addMaintenance, // Can add maintenance
      AppFeature.editMaintenance, // Can edit maintenance
      AppFeature.deleteMaintenance, // Can delete maintenance
      // NO: cloud features, unlimited vehicles, export, OCR, delete vehicles
    },

    // ==================== FREE (Registered) ====================
    // Has account - cloud backup and sync, still limited to 1 vehicle
    UserTier.free: {
      // Vehicle management
      AppFeature.addVehicle, // Can add vehicles (up to limit)
      AppFeature.deleteVehicle, // NEW: Can delete vehicles
      AppFeature.editVehicle,

      // Maintenance
      AppFeature.addMaintenance,
      AppFeature.editMaintenance,
      AppFeature.deleteMaintenance,
      // Cloud features (NEW!)
      AppFeature.cloudBackup,
      AppFeature.cloudSync,
      AppFeature.multiDeviceSync,

      // NO: unlimited vehicles, OCR, advanced features
    },

    // ==================== PREMIUM ====================
    // Paid - everything!
    UserTier.premium: {
      // Basic vehicle management
      AppFeature.addVehicle,
      AppFeature.deleteVehicle,
      AppFeature.editVehicle,
      AppFeature.unlimitedVehicles, // NEW: No limits!
      // Maintenance
      AppFeature.addMaintenance,
      AppFeature.editMaintenance,
      AppFeature.deleteMaintenance,
      AppFeature.unlimitedMaintenance,
      AppFeature.exportMaintenancePDF,

      // Cloud
      AppFeature.cloudBackup,
      AppFeature.cloudSync,
      AppFeature.multiDeviceSync,

      // Export & Import
      AppFeature.exportAllData,
      AppFeature.importData,

      // Advanced features
      AppFeature.ocrScanning,
      AppFeature.besiktningReminders,
      AppFeature.customCategories,
      AppFeature.advancedStatistics,

      // Premium perks
      AppFeature.removeAds,
      AppFeature.prioritySupport,
      AppFeature.earlyAccess,

      // Future features (uncomment when implemented)
      // AppFeature.fuelTracking,
      // AppFeature.expenseAnalytics,
      // AppFeature.serviceReminders,
      // AppFeature.shareWithMechanic,
    },
  };

  /// Vehicle limits per tier
  /// null = unlimited
  static const Map<UserTier, int?> vehicleLimits = {
    UserTier.unregistered: 1, // 1 vehicle max
    UserTier.free: 1, // 1 vehicle max (cloud backup though!)
    UserTier.premium: null, // null = unlimited
  };

  /// Maintenance record limits per tier
  /// null = unlimited
  static const Map<UserTier, int?> maintenanceLimits = {
    UserTier.unregistered: null, // Unlimited (just limited vehicles)
    UserTier.free: null, // Unlimited
    UserTier.premium: null, // Unlimited
  };

  // ==================== GETTERS ====================

  /// Get features for a specific tier
  static Set<AppFeature> getFeaturesForTier(UserTier tier) {
    return tierFeatures[tier] ?? {};
  }

  /// Get vehicle limit for a tier
  static int? getVehicleLimitForTier(UserTier tier) {
    return vehicleLimits[tier];
  }

  /// Get maintenance limit for a tier
  static int? getMaintenanceLimitForTier(UserTier tier) {
    return maintenanceLimits[tier];
  }

  /// Check if a tier has a specific feature
  static bool tierHasFeature(UserTier tier, AppFeature feature) {
    return tierFeatures[tier]?.contains(feature) ?? false;
  }

  // ==================== FEATURE COMPARISONS ====================

  /// Get all features that require premium (not available in free)
  static Set<AppFeature> get premiumOnlyFeatures {
    final freeFeatures = tierFeatures[UserTier.free] ?? {};
    final premiumFeatures = tierFeatures[UserTier.premium] ?? {};
    return premiumFeatures.difference(freeFeatures);
  }

  /// Get all features that require an account (free or premium, not unregistered)
  static Set<AppFeature> get accountRequiredFeatures {
    final unregisteredFeatures = tierFeatures[UserTier.unregistered] ?? {};
    final freeFeatures = tierFeatures[UserTier.free] ?? {};
    return freeFeatures.difference(unregisteredFeatures);
  }

  /// Get features gained by upgrading from one tier to another
  static Set<AppFeature> getUpgradeFeatures(UserTier from, UserTier to) {
    final fromFeatures = tierFeatures[from] ?? {};
    final toFeatures = tierFeatures[to] ?? {};
    return toFeatures.difference(fromFeatures);
  }

  // ==================== DISPLAY HELPERS ====================

  /// Get user-friendly tier name
  static String getTierDisplayName(UserTier tier) {
    switch (tier) {
      case UserTier.unregistered:
        return 'Ej inloggad';
      case UserTier.free:
        return 'Gratis';
      case UserTier.premium:
        return 'Premium';
    }
  }

  /// Get tier description
  static String getTierDescription(UserTier tier) {
    switch (tier) {
      case UserTier.unregistered:
        return 'Lokal lagring, 1 fordon';
      case UserTier.free:
        return 'Molnbackup, 1 fordon';
      case UserTier.premium:
        return 'Alla funktioner, obegränsat';
    }
  }
}
