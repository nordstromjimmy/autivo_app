import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vehicle_provider.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/paywall_screen.dart';
import '../utils/premium_features.dart';

class VehicleLimitChecker {
  // Free tier limit
  static const int FREE_VEHICLE_LIMIT = 1;

  /// Check if user can add a vehicle and show appropriate screen if not
  /// Returns true if user can add, false otherwise
  static Future<bool> checkLimitAndShowPaywall(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final premiumFeatures = ref.read(premiumFeaturesProvider);
    final vehicles = ref.read(vehiclesProvider);
    final currentCount = vehicles.length;

    // Check if can add vehicle
    final canAdd = await premiumFeatures.canAddVehicle(currentCount);

    if (canAdd) {
      return true; // User can add vehicle
    }

    // User has reached limit - show appropriate screen
    if (!context.mounted) return false;

    // Check if they have an account
    final hasAccount = premiumFeatures.hasAccount;

    if (hasAccount) {
      // Has account but no premium - show paywall
      return await _showPaywall(context);
    } else {
      // No account - need to create one first
      return await _showAccountRequiredDialog(context);
    }
  }

  /// Show the paywall screen
  static Future<bool> _showPaywall(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const PaywallScreen()),
    );

    // Return true if purchase was successful
    return result ?? false;
  }

  /// Show dialog explaining account is required
  static Future<bool> _showAccountRequiredDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.account_circle, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Konto krävs'),
          ],
        ),
        content: const Text(
          'För att lägga till fler fordon och använda Premium-funktioner '
          'behöver du ett konto.\n\n'
          'Premium inkluderar molnsynkronisering, OCR-verifiering och andra '
          'funktioner som kräver ett konto.\n\n'
          'Vill du skapa ett gratis konto nu?',
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

  /// Get a user-friendly message about the vehicle limit
  static String getLimitMessage(int currentCount, bool isPremium) {
    if (isPremium) {
      return 'Du kan lägga till obegränsat antal fordon';
    } else {
      final remaining = FREE_VEHICLE_LIMIT - currentCount;
      if (remaining > 0) {
        return 'Du kan lägga till $remaining fordon till (gratis version)';
      } else {
        return 'Du har nått gränsen för gratis version. Uppgradera för obegränsat antal fordon.';
      }
    }
  }
}
