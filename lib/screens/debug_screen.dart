import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:uuid/uuid.dart';
import '../features/premium/providers/combined_premium_provider.dart';
import '../features/premium/providers/purchase_provider.dart';
import '../features/premium/utils/feature_checker.dart';
import '../features/premium/utils/premium_features.dart';
import '../core/utils/helpers/custom_snackbar.dart';

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) {
      return const Scaffold(body: Center(child: Text('Debug mode only')));
    }

    final checker = ref.watch(featureCheckerProvider);
    final premiumFeatures = ref.watch(premiumFeaturesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Debug Tools'),
        backgroundColor: Colors.red[700],
      ),
      body: ListView(
        children: [
          // Warning Banner
          Container(
            color: Colors.orange[100],
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[900]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Development Only - These tools modify app state!',
                    style: TextStyle(
                      color: Colors.orange[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Current Status
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Status:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(),
                  _buildStatusRow('Tier', checker.tierName),
                  _buildStatusRow(
                    'Has Account',
                    '${premiumFeatures.hasAccount}',
                  ),
                  _buildStatusRow(
                    'Has Premium',
                    '${premiumFeatures.hasPremium}',
                  ),
                  _buildStatusRow(
                    'RevenueCat',
                    '${premiumFeatures.hasPremiumFromRevenueCat}',
                  ),
                  _buildStatusRow(
                    'Supabase',
                    '${premiumFeatures.hasPremiumFromSupabase}',
                  ),
                  _buildStatusRow(
                    'Vehicle Limit',
                    '${checker.vehicleLimit ?? "∞"}',
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Premium Status Tools:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.blue),
            title: const Text('Refresh Premium Status'),
            subtitle: const Text('Invalidate all premium providers'),
            onTap: () => _refreshPremium(ref, context),
          ),

          ListTile(
            leading: const Icon(Icons.clear, color: Colors.orange),
            title: const Text('Clear RevenueCat Cache'),
            subtitle: const Text('Clear local cache (may re-sync from server)'),
            onTap: () => _clearRevenueCatCache(ref, context),
          ),

          ListTile(
            leading: const Icon(Icons.person_off, color: Colors.red),
            title: const Text('⚠️ Reset RevenueCat User'),
            subtitle: const Text('Create new anonymous user (NUCLEAR OPTION)'),
            onTap: () => _resetRevenueCatUser(ref, context),
          ),

          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Info:', style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          ListTile(
            leading: const Icon(Icons.info, color: Colors.blue),
            title: const Text('View RevenueCat Customer Info'),
            subtitle: const Text('Show raw customer data'),
            onTap: () => _showRevenueCatInfo(context),
          ),

          ListTile(
            leading: const Icon(Icons.account_circle, color: Colors.blue),
            title: const Text('View RevenueCat User ID'),
            subtitle: const Text('Show current app user ID'),
            onTap: () => _showAppUserId(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _refreshPremium(WidgetRef ref, BuildContext context) {
    ref.invalidate(premiumStatusProvider);
    ref.invalidate(supabasePremiumStatusProvider);
    ref.invalidate(combinedPremiumStatusProvider);
    ref.invalidate(premiumFeaturesProvider);
    ref.invalidate(userTierProvider);
    ref.invalidate(featureCheckerProvider);

    CustomSnackBar.showSuccess(context, 'Premium status refreshed');
  }

  Future<void> _clearRevenueCatCache(
    WidgetRef ref,
    BuildContext context,
  ) async {
    try {
      await Purchases.invalidateCustomerInfoCache();
      _refreshPremium(ref, context);

      if (context.mounted) {
        CustomSnackBar.showInfo(
          context,
          'Cache cleared! Note: RevenueCat may re-sync from server.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Error: $e');
      }
    }
  }

  Future<void> _resetRevenueCatUser(WidgetRef ref, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Reset RevenueCat User?'),
          ],
        ),
        content: const Text(
          '⚠️ WARNING: This will:\n\n'
          '• Create new anonymous user ID\n'
          '• Reset all premium status\n'
          '• Cannot be undone!\n\n'
          'This is the NUCLEAR OPTION for testing.\n\n'
          'App will need to restart after this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset User'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Generate new anonymous user ID
      final newUserId = 'anon_${const Uuid().v4()}';

      // Check if current user is anonymous
      final customerInfo = await Purchases.getCustomerInfo();
      final isAnonymous = customerInfo.originalAppUserId.startsWith(
        '\$RCAnonymousID',
      );

      if (isAnonymous) {
        // Already anonymous - just switch to new anonymous ID
        await Purchases.logIn(newUserId);
      } else {
        // Identified user - log out first, then login with new ID
        await Purchases.logOut();
        await Purchases.logIn(newUserId);
      }

      // Clear all premium providers
      _refreshPremium(ref, context);

      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('✅ User Reset Complete'),
            content: Text(
              'RevenueCat user has been reset.\n\n'
              'New User ID: $newUserId\n\n'
              'You should now appear as FREE tier.\n\n'
              'Close and reopen the app to see changes.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Exit debug screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ Error resetting user: $e');
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Error resetting user: $e');
      }
    }
  }

  Future<void> _showRevenueCatInfo(BuildContext context) async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();

      final hasActiveEntitlements = customerInfo.entitlements.active.isNotEmpty;
      final entitlementsList = customerInfo.entitlements.all.entries
          .map((e) => '${e.key}: ${e.value.isActive ? "ACTIVE" : "inactive"}')
          .join('\n');

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('RevenueCat Customer Info'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Has Active Entitlements: $hasActiveEntitlements',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const Text(
                    'Entitlements:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(entitlementsList.isNotEmpty ? entitlementsList : 'None'),
                  const SizedBox(height: 8),
                  const Text(
                    'Active Subscriptions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    customerInfo.activeSubscriptions.isEmpty
                        ? 'None'
                        : customerInfo.activeSubscriptions.join(', '),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Original App User ID:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(customerInfo.originalAppUserId),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Error fetching info: $e');
      }
    }
  }

  Future<void> _showAppUserId(BuildContext context) async {
    try {
      final appUserId = await Purchases.appUserID;

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('RevenueCat User ID'),
            content: SelectableText(
              'Current App User ID:\n\n$appUserId\n\n'
              'This is the ID RevenueCat uses to track purchases.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Error: $e');
      }
    }
  }
}
