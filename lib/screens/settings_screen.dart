import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_info_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/combined_premium_provider.dart';
import '../providers/purchase_provider.dart';
import '../services/sync_manager.dart';
import '../utils/custom_snackbar.dart';
import '../utils/feature_checker.dart';
import '../utils/premium_features.dart';
import '../utils/user_session_tracker.dart';
import '../widgets/premium_status_card.dart';
import 'auth/sign_in_screen.dart';

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
          // Account Section
          const _SectionHeader(title: 'Konto'),

          if (isSignedIn && currentUser != null) ...[
            // Signed in - show account info
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: Text(
                  (currentUser.email ?? '?')[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(currentUser.email ?? 'Okänd användare'),
              subtitle: const Text('Inloggad'),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
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
                                'Logga in för att säkerhetskopiera din data',
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

                    if (syncManager.hasLocalDataToMigrate()) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${syncManager.totalPendingCount} fordon/poster kommer synkas när du loggar in',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          // App Info Section
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
          PremiumDebugWidget(),
        ],
      ),
    );
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

    // Perform sync (SyncManager automatically refreshes providers)
    final syncManager = ref.read(syncManagerProvider);
    final result = await syncManager.fullSync();

    // Close loading dialog
    if (context.mounted) Navigator.pop(context);

    // Show result
    if (result.success) {
      if (result.totalSynced > 0) {
        // Show what was synced: "Synkroniserat: 2 fordon, 5 poster"
        CustomSnackBar.showSuccess(context, result.toString());
      } else {
        // Nothing to sync
        CustomSnackBar.showSuccess(context, 'Allt synkroniserat');
      }
    } else {
      // Error occurred - show actual error message
      CustomSnackBar.showError(context, result.message);
    }
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logga ut'),
        content: const Text(
          'Är du säker på att du vill logga ut?\n\n'
          'Din data finns kvar lokalt och synkas när du loggar in igen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logga ut'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      // Step 1: Sign out from Supabase
      await Supabase.instance.client.auth.signOut();

      // Step 2: Clear session (but NOT local data!)
      await UserSessionTracker.clearUserId();

      // Step 3: Invalidate ALL auth-related providers
      // (vehicles stay cached for offline use)
      ref.invalidate(premiumStatusProvider);
      ref.invalidate(supabasePremiumStatusProvider);
      ref.invalidate(combinedPremiumStatusProvider);

      // ✅ ADD THESE - Invalidate feature gate providers
      ref.invalidate(premiumFeaturesProvider);
      ref.invalidate(userTierProvider);
      ref.invalidate(featureCheckerProvider);

      if (context.mounted) {
        CustomSnackBar.showSuccess(context, 'Utloggad');
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      print('❌ Error during logout: $e');

      if (context.mounted) {
        CustomSnackBar.showError(
          context,
          'Fel vid utloggning: ${e.toString()}',
        );
      }
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
          : const Icon(Icons.check, color: Colors.green),
    );
  }
}

class PremiumDebugWidget extends ConsumerWidget {
  const PremiumDebugWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premiumFeatures = ref.watch(premiumFeaturesProvider);
    final supabasePremiumAsync = ref.watch(supabasePremiumStatusProvider);
    final user = Supabase.instance.client.auth.currentUser;

    return Card(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🐛 Premium Debug Info (Users Table)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Divider(),

            // User info
            Text('Has Account: ${premiumFeatures.hasAccount}'),
            Text('User ID: ${user?.id ?? "null"}'),
            Text('Email: ${user?.email ?? "null"}'),

            SizedBox(height: 8),

            // Supabase users table status
            Text(
              'Supabase Users Table:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            supabasePremiumAsync.when(
              data: (isPremium) => Text('is_premium: $isPremium'),
              loading: () => Text('Loading...'),
              error: (err, stack) =>
                  Text('Error: $err', style: TextStyle(color: Colors.red)),
            ),

            SizedBox(height: 8),

            // Premium status checks
            Text(
              'Premium Checks:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'RevenueCat: ${premiumFeatures.hasPremiumFromRevenueCat ? "✅" : "❌"}',
            ),
            Text(
              'Supabase: ${premiumFeatures.hasPremiumFromSupabase ? "✅" : "❌"}',
            ),
            Text(
              'Combined: ${premiumFeatures.hasPremium ? "✅ PREMIUM" : "❌ FREE"}',
            ),

            SizedBox(height: 8),

            // Buttons
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    // Refresh providers
                    ref.invalidate(supabasePremiumStatusProvider);
                    ref.invalidate(premiumStatusProvider);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Refreshed! Check values above.')),
                    );
                  },
                  icon: Icon(Icons.refresh, size: 16),
                  label: Text('Refresh', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),

                ElevatedButton.icon(
                  onPressed: () async {
                    // Fetch fresh data from database
                    if (user == null) return;

                    try {
                      final response = await Supabase.instance.client
                          .from('users')
                          .select()
                          .eq('id', user.id)
                          .single();

                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Users Table Data'),
                            content: SingleChildScrollView(
                              child: Text(response.toString()),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Close'),
                              ),
                            ],
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(Icons.table_chart, size: 16),
                  label: Text('View DB', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
