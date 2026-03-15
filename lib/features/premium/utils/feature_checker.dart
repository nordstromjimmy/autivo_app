import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'feature_gates.dart';
import 'feature_config.dart';
import 'premium_features.dart';

// ==================== PROVIDERS ====================

/// Provider for current user tier
/// This automatically updates when auth/premium status changes
final userTierProvider = Provider<UserTier>((ref) {
  final premiumFeatures = ref.watch(premiumFeaturesProvider);

  if (!premiumFeatures.hasAccount) {
    return UserTier.unregistered;
  }

  if (premiumFeatures.hasPremium) {
    return UserTier.premium;
  }

  return UserTier.free;
});

/// Provider for feature access checking
/// This is the main provider you'll use throughout the app
final featureCheckerProvider = Provider<FeatureChecker>((ref) {
  final tier = ref.watch(userTierProvider);
  return FeatureChecker(tier);
});

// ==================== FEATURE CHECKER CLASS ====================

/// Check if user can access features based on their tier
///
/// Usage:
/// ```dart
/// final checker = ref.watch(featureCheckerProvider);
/// if (checker.canUse(AppFeature.ocrScanning)) {
///   // Show OCR button
/// } else {
///   // Show upgrade prompt
/// }
/// ```
class FeatureChecker {
  final UserTier currentTier;

  FeatureChecker(this.currentTier);

  // ==================== FEATURE CHECKS ====================

  /// Check if user has access to a feature
  bool canUse(AppFeature feature) {
    return FeatureConfig.tierHasFeature(currentTier, feature);
  }

  /// Check multiple features (user needs ALL of them)
  bool canUseAll(List<AppFeature> features) {
    return features.every((f) => canUse(f));
  }

  /// Check multiple features (user needs ANY of them)
  bool canUseAny(List<AppFeature> features) {
    return features.any((f) => canUse(f));
  }

  // ==================== LIMITS ====================

  /// Get vehicle limit for current tier (null = unlimited)
  int? get vehicleLimit {
    return FeatureConfig.getVehicleLimitForTier(currentTier);
  }

  /// Check if unlimited vehicles
  bool get hasUnlimitedVehicles {
    return vehicleLimit == null;
  }

  /// Check if user can add a vehicle given current count
  bool canAddVehicle(int currentCount) {
    final limit = vehicleLimit;
    if (limit == null) return true; // Unlimited
    return currentCount < limit;
  }

  /// Get remaining vehicle slots (null = unlimited)
  int? getRemainingVehicleSlots(int currentCount) {
    final limit = vehicleLimit;
    if (limit == null) return null; // Unlimited
    final remaining = limit - currentCount;
    return remaining > 0 ? remaining : 0;
  }

  /// Get maintenance limit for current tier (null = unlimited)
  int? get maintenanceLimit {
    return FeatureConfig.getMaintenanceLimitForTier(currentTier);
  }

  // ==================== TIER INFO ====================

  /// Get tier name for display
  String get tierName {
    return FeatureConfig.getTierDisplayName(currentTier);
  }

  /// Get tier description
  String get tierDescription {
    return FeatureConfig.getTierDescription(currentTier);
  }

  /// Check if user is premium
  bool get isPremium {
    return currentTier == UserTier.premium;
  }

  /// Check if user has an account (free or premium)
  bool get hasAccount {
    return currentTier != UserTier.unregistered;
  }

  /// Check if user is unregistered
  bool get isUnregistered {
    return currentTier == UserTier.unregistered;
  }

  // ==================== UPGRADE MESSAGING ====================

  /// Get required tier for a feature
  UserTier? getRequiredTier(AppFeature feature) {
    // Check tiers from lowest to highest
    for (final tier in UserTier.values) {
      if (FeatureConfig.tierHasFeature(tier, feature)) {
        return tier;
      }
    }
    return null; // Feature not available in any tier
  }

  /// Get upgrade message for a feature
  String getUpgradeMessage(AppFeature feature) {
    final requiredTier = getRequiredTier(feature);
    final featureName = FeatureMetadata.getDisplayName(feature);

    switch (requiredTier) {
      case UserTier.unregistered:
        return '$featureName är tillgänglig för alla';
      case UserTier.free:
        if (currentTier == UserTier.unregistered) {
          return '$featureName kräver ett gratis konto';
        }
        return '$featureName är tillgänglig';
      case UserTier.premium:
        if (currentTier == UserTier.unregistered) {
          return '$featureName kräver Premium.';
        } else {
          return '$featureName är endast för Premium-användare';
        }
      case null:
        return '$featureName är inte tillgänglig';
    }
  }

  /// Get call-to-action for a feature (what button to show)
  String getUpgradeCTA(AppFeature feature) {
    final requiredTier = getRequiredTier(feature);

    switch (requiredTier) {
      case UserTier.free:
        if (currentTier == UserTier.unregistered) {
          return 'Skapa konto';
        }
        return 'Tillgänglig';
      case UserTier.premium:
        if (currentTier == UserTier.unregistered) {
          return 'Skapa konto';
        } else {
          return 'Uppgradera till Premium';
        }
      default:
        return 'Uppgradera';
    }
  }

  // ==================== VEHICLE LIMIT MESSAGES ====================

  /// Get user-friendly message about vehicle limit
  String getVehicleLimitMessage(int currentCount) {
    final limit = vehicleLimit;

    if (limit == null) {
      return 'Du kan lägga till obegränsat antal fordon';
    }

    final remaining = limit - currentCount;

    if (remaining > 0) {
      return 'Du kan lägga till $remaining fordon till ($tierName)';
    } else {
      if (currentTier == UserTier.unregistered) {
        return 'Du har nått gränsen. Skapa ett gratis konto för molnbackup eller uppgradera till Premium för obegränsat antal fordon.';
      } else {
        return 'Du har nått gränsen för $tierName. Uppgradera till Premium för obegränsat antal fordon.';
      }
    }
  }

  /// Get short vehicle limit status (e.g., "1/1" or "5/∞")
  String getVehicleLimitStatus(int currentCount) {
    final limit = vehicleLimit;
    if (limit == null) return '$currentCount/∞';
    return '$currentCount/$limit';
  }

  // ==================== FEATURE LISTS ====================

  /// Get all features available to current tier
  Set<AppFeature> get availableFeatures {
    return FeatureConfig.getFeaturesForTier(currentTier);
  }

  /// Get features that would be gained by upgrading to premium
  Set<AppFeature> get upgradeFeatures {
    if (currentTier == UserTier.premium) return {};
    return FeatureConfig.getUpgradeFeatures(currentTier, UserTier.premium);
  }

  /// Get features that would be gained by creating an account (if unregistered)
  Set<AppFeature> get accountFeatures {
    if (currentTier != UserTier.unregistered) return {};
    return FeatureConfig.getUpgradeFeatures(
      UserTier.unregistered,
      UserTier.free,
    );
  }
}
