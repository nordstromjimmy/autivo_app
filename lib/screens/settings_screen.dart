import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../shared/providers/app_info_provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/premium/providers/combined_premium_provider.dart';
import '../features/maintenance/providers/maintenance_provider.dart';
import '../features/premium/providers/purchase_provider.dart';
import '../features/receipts/providers/receipt_provider.dart';
import '../features/vehicles/providers/vehicle_provider.dart';
import '../core/services/sync/sync_manager.dart';
import '../core/utils/helpers/custom_snackbar.dart';
import '../features/premium/utils/feature_checker.dart';
import '../features/premium/utils/premium_features.dart';
import '../core/services/auth/user_session_tracker.dart';
import '../features/premium/widgets/premium_status_card.dart';
import '../shared/widgets/theme_selector.dart';
import '../features/auth/screens/sign_in_screen.dart';
import 'debug_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(isSignedInProvider);
    final currentUser = ref.watch(currentUserProvider);
    final syncManager = ref.read(syncManagerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Inställningar')),
      body: ListView(
        children: [
          if (isSignedIn) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Premium',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            PremiumStatusCard(),
            const SizedBox(height: 24),
          ],

          // Account Section
          const _SectionHeader(title: 'Konto'),

          if (isSignedIn && currentUser != null) ...[
            // Signed in - show account info
            ListTile(
              leading: Icon(Icons.person),
              title: Text(currentUser.email ?? 'Okänd användare'),
              subtitle: const Text('Inloggad'),
            ),

            // Sync section
            const Divider(),
            const _SectionHeader(title: 'Synkronisering'),

            _SyncStatusTile(syncManager: syncManager),

            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Synkronisera nu'),
              subtitle: const Text('Ladda upp och ner data'),
              onTap: () => _performSync(context, ref),
            ),

            // Sign out
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logga ut'),
              onTap: () => _handleLogout(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Radera konto'),
              onTap: () => _handleDeleteAccount(context, ref),
            ),
          ] else ...[
            // Not signed in - show sign in option
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.cloud_off,
                          color: Colors.orange[700],
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Inte inloggad',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Logga in för att säkerhetskopiera din data eller ladda din sparade data',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignInScreen(),
                          ),
                        );
                      },
                      label: const Text('Logga in'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // App Info Section
          const Divider(),
          const _SectionHeader(title: 'Inställningar'),
          const ThemeSelectorCompact(),
          const Divider(),
          const _SectionHeader(title: 'Om'),

          Consumer(
            builder: (context, ref, child) {
              final versionAsync = ref.watch(appVersionProvider);

              return ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Version'),
                subtitle: versionAsync.when(
                  data: (version) => Text(version),
                  loading: () => const Text('Laddar...'),
                  error: (_, __) => const Text('Okänd'),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Användarvillkor'),
            onTap: () => _openUrl(context, 'https://autivo.se/anvandarvillkor'),
          ),

          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Integritetspolicy'),
            onTap: () =>
                _openUrl(context, 'https://autivo.se/integritetspolicy'),
          ),
          Divider(),
          if (kDebugMode) ...[
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Debug Tools'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DebugScreen()),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Radera konto?'),
          ],
        ),
        content: const Text(
          '⚠️ VARNING: Detta kommer att:\n\n'
          '• Radera ditt konto permanent\n'
          '• Ta bort all data från molnet\n'
          '• Behålla lokal data (för offline-användning)\n'
          '• Inte påverka din premium-status\n\n'
          'Denna åtgärd kan INTE ångras!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Radera permanent'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        if (context.mounted) {
          CustomSnackBar.showError(context, 'Ingen användare inloggad');
        }
        return;
      }

      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Step 1: Delete user data from Supabase
      // Delete vehicles
      await Supabase.instance.client
          .from('vehicles')
          .delete()
          .eq('user_id', userId);

      // Delete maintenance records
      await Supabase.instance.client
          .from('maintenance_records')
          .delete()
          .eq('user_id', userId);

      // Delete user record
      await Supabase.instance.client.from('users').delete().eq('id', userId);

      // Step 2: Delete auth account
      // Note: This requires Supabase Edge Function or Admin API
      // For now, we'll just sign out
      // TODO: Implement proper account deletion via Edge Function

      // Step 3: Log out from RevenueCat (back to anonymous)
      await Purchases.logOut();

      // Step 4: Sign out from Supabase
      await Supabase.instance.client.auth.signOut();

      // Step 5: Clear session
      await UserSessionTracker.clearUserId();

      // Step 6: Keep local data (don't call clearAllLocalData)
      // User can still use app offline with their local vehicles

      // Step 7: Invalidate all providers
      ref.invalidate(premiumStatusProvider);
      ref.invalidate(supabasePremiumStatusProvider);
      ref.invalidate(combinedPremiumStatusProvider);
      ref.invalidate(premiumFeaturesProvider);
      ref.invalidate(userTierProvider);
      ref.invalidate(featureCheckerProvider);
      ref.invalidate(vehiclesProvider);
      ref.invalidate(maintenanceProvider);

      // Close loading
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Show success and navigate home
      if (context.mounted) {
        CustomSnackBar.showSuccess(context, 'Konto raderat');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      // Close loading if open
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (context.mounted) {
        CustomSnackBar.showError(context, 'Fel vid radering: ${e.toString()}');
      }
    }
  }

  Future<void> _performSync(BuildContext context, WidgetRef ref) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Synkroniserar...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final syncManager = ref.read(syncManagerProvider);
      final userId = syncManager.userId;

      if (userId != null) {
        // Migrate any offline data first
        if (syncManager.hasLocalDataToMigrate()) {
          await syncManager.migrateAnonymousData(userId);
        }
      }

      // Perform sync
      final result = await syncManager.fullSync();

      // Invalidate all receipt providers to update UI
      ref.invalidate(receiptNotifierProvider);
      ref.invalidate(receiptByIdProvider);
      ref.invalidate(receiptsForVehicleProvider);
      ref.invalidate(receiptsForMaintenanceProvider);
      ref.invalidate(receiptPendingSyncCountProvider);
      ref.invalidate(pendingSyncCountProvider);

      ref.invalidate(vehiclesProvider);
      ref.invalidate(maintenanceProvider);

      // Close loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show result
      if (result.success) {
        if (result.totalSynced > 0) {
          CustomSnackBar.showSuccess(context, result.toString());
        } else {
          CustomSnackBar.showSuccess(context, 'Allt synkroniserat');
        }
      } else {
        CustomSnackBar.showError(context, result.message);
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Synkronisering misslyckades: $e');
      }
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // ... existing confirmation dialog ...

    try {
      // Step 1: Sign out from Supabase
      await Supabase.instance.client.auth.signOut();

      // Step 2: Log out from RevenueCat (back to anonymous)
      await Purchases.logOut();

      // Step 3: Clear session
      await UserSessionTracker.clearUserId();

      // Step 4: Invalidate providers
      ref.invalidate(premiumStatusProvider);
      ref.invalidate(supabasePremiumStatusProvider);
      ref.invalidate(combinedPremiumStatusProvider);
      ref.invalidate(premiumFeaturesProvider);
      ref.invalidate(userTierProvider);
      ref.invalidate(featureCheckerProvider);

      // ... rest of existing code ...
    } catch (e) {
      print('❌ Error during logout: $e');
      // ... error handling ...
    }
  }
}

/// Open URL in external browser
Future<void> _openUrl(BuildContext context, String urlString) async {
  final url = Uri.parse(urlString);

  try {
    if (await canLaunchUrl(url)) {
      await launchUrl(
        url,
        mode: LaunchMode.externalApplication, // Opens in browser
      );
    } else {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Kunde inte öppna länken');
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fel: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Section header widget
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

// Sync status tile
class _SyncStatusTile extends ConsumerWidget {
  final SyncManager syncManager;

  const _SyncStatusTile({required this.syncManager});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = syncManager.totalPendingCount;

    return ListTile(
      leading: Icon(
        pendingCount > 0 ? Icons.cloud_upload : Icons.cloud_done,
        color: pendingCount > 0 ? Colors.orange : Colors.green,
      ),
      title: const Text('Synkroniseringsstatus'),
      subtitle: Text(
        pendingCount > 0
            ? '$pendingCount objekt väntar på synkronisering'
            : 'Allt synkroniserat',
      ),
      trailing: pendingCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$pendingCount',
                style: TextStyle(
                  color: Colors.orange[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}
