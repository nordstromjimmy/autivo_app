import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vehicles/providers/vehicle_provider.dart';
import '../../auth/screens/sign_up_screen.dart';
import '../screens/paywall_screen.dart';
import 'feature_gates.dart';
import 'feature_checker.dart';

/// Helper for checking vehicle limits and showing upgrade prompts
///
/// Now uses the centralized feature gate system!
/// All tier logic is in feature_config.dart
class VehicleLimitChecker {
  /// Check if user can add a vehicle and show appropriate screen if not
  /// Returns true if user can add, false otherwise
  static Future<bool> checkLimitAndShowPaywall(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final checker = ref.read(featureCheckerProvider);
    final vehicles = ref.read(vehiclesProvider);
    final currentCount = vehicles.length;

    // Check if can add vehicle using new system
    final canAdd = checker.canAddVehicle(currentCount);

    if (canAdd) {
      return true; // User can add vehicle
    }

    // User has reached limit - show appropriate screen based on tier
    if (!context.mounted) return false;

    final tier = checker.currentTier;

    switch (tier) {
      case UserTier.unregistered:
        // No account - show account creation prompt
        return await _showAccountRequiredDialog(context, checker, currentCount);

      case UserTier.free:
        // Has account but no premium - show paywall
        return await _showPaywall(context, checker, currentCount);

      case UserTier.premium:
        // Should never happen (premium = unlimited)
        return true;
    }
  }

  /// Show the paywall screen for free users
  static Future<bool> _showPaywall(
    BuildContext context,
    FeatureChecker checker,
    int currentCount,
  ) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const PaywallScreen()),
    );

    // Return true if purchase was successful
    return result ?? false;
  }

  /// Show dialog for unregistered users
  static Future<bool> _showAccountRequiredDialog(
    BuildContext context,
    FeatureChecker checker,
    int currentCount,
  ) async {
    final limitMessage = checker.getVehicleLimitMessage(currentCount);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_circle, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text('Konto krävs'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(limitMessage),
            const SizedBox(height: 16),
            const Text(
              'Med ett gratis konto får du:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._buildAccountBenefits(checker),
            const SizedBox(height: 16),
            const Text(
              'Eller uppgradera till Premium för obegränsat antal fordon!',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, false);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignUpScreen()),
              );
            },
            child: const Text('Skapa konto'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Build list of benefits for creating an account
  static List<Widget> _buildAccountBenefits(FeatureChecker checker) {
    // Get features gained by creating account
    final features = checker.accountFeatures;

    // Key features to highlight
    final keyFeatures = [
      AppFeature.cloudBackup,
      AppFeature.cloudSync,
      AppFeature.multiDeviceSync,
      AppFeature.ocrScanning,
    ];

    return keyFeatures
        .where((f) => features.contains(f))
        .map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  FeatureMetadata.getIcon(feature),
                  size: 16,
                  color: Colors.green[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    FeatureMetadata.getDisplayName(feature),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }
}
