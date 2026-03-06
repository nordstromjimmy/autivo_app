import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/purchase_provider.dart';
import '../providers/vehicle_provider.dart';
import '../screens/paywall_screen.dart';

class VehicleLimitChecker {
  static const int FREE_VEHICLE_LIMIT = 1;

  /// Check if user can add more vehicles
  /// Returns true if allowed, false if limit reached
  static Future<bool> canAddVehicle(WidgetRef ref) async {
    // Check if premium
    final premiumAsync = ref.read(premiumStatusProvider);
    final isPremium = premiumAsync.value ?? false;

    if (isPremium) {
      return true; // Premium users have unlimited vehicles
    }

    // Check vehicle count for free users
    final vehicles = ref.read(vehiclesProvider);
    return vehicles.length < FREE_VEHICLE_LIMIT;
  }

  /// Show paywall if vehicle limit reached
  /// Returns true if user upgraded, false otherwise
  static Future<bool> checkLimitAndShowPaywall(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final canAdd = await canAddVehicle(ref);

    if (canAdd) {
      return true; // Can proceed
    }

    // Show paywall
    if (context.mounted) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const PaywallScreen()),
      );

      return result ?? false; // True if purchased, false otherwise
    }

    return false;
  }

  /// Get remaining vehicle slots for free users
  static int getRemainingSlots(WidgetRef ref, bool isPremium) {
    if (isPremium) {
      return 999; // Unlimited
    }

    final vehicles = ref.read(vehiclesProvider);
    final remaining = FREE_VEHICLE_LIMIT - vehicles.length;
    return remaining < 0 ? 0 : remaining.toInt();
  }

  /// Show upgrade prompt dialog
  static Future<void> showUpgradeDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔒 Fordonsgräns nådd'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Du har nått gränsen för gratis-versionen (2 fordon).',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Med Premium får du:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildBenefit('Obegränsat antal fordon'),
                  _buildBenefit('Molnsynkronisering'),
                  _buildBenefit('OCR-verifiering'),
                  _buildBenefit('Avancerade funktioner'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Senare'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaywallScreen()),
              );
            },
            child: const Text('Uppgradera'),
          ),
        ],
      ),
    );
  }

  static Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

/// Widget to show vehicle count and upgrade prompt
class VehicleCountWidget extends ConsumerWidget {
  const VehicleCountWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumAsync = ref.watch(premiumStatusProvider);
    final vehicles = ref.watch(vehiclesProvider);

    return premiumAsync.when(
      data: (isPremium) {
        if (isPremium) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[600]!, Colors.amber[800]!],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Premium • ${vehicles.length} fordon',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        // Free user
        final remaining = VehicleLimitChecker.getRemainingSlots(ref, false);
        final color = remaining == 0 ? Colors.red : Colors.orange;

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PaywallScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: color[700], size: 16),
                const SizedBox(width: 4),
                Text(
                  '${vehicles.length}/${VehicleLimitChecker.FREE_VEHICLE_LIMIT} fordon',
                  style: TextStyle(
                    color: color[900],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
