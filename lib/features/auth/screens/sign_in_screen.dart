import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/storage/storage_service.dart';
import '../../receipts/providers/receipt_provider.dart';
import '../providers/auth_provider.dart';
import '../../premium/providers/purchase_provider.dart';
import '../../premium/providers/combined_premium_provider.dart';
import '../../maintenance/providers/maintenance_provider.dart';
import '../../vehicles/providers/vehicle_provider.dart';
import '../../../core/services/sync/sync_manager.dart';
import '../../../core/services/sync/sync_service.dart';
import '../../../core/utils/tracking/clear_local_data.dart';
import '../../../core/utils/helpers/custom_snackbar.dart';
import '../../premium/utils/feature_checker.dart';
import '../../../core/utils/tracking/maintenance_deletion_tracker.dart';
import '../../premium/utils/premium_features.dart';
import '../../../core/services/auth/user_session_tracker.dart';
import '../../../screens/home_screen.dart';
import 'sign_up_screen.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isProcessing = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate() && !_isProcessing) {
      setState(() {
        _isProcessing = true;
      });

      try {
        // Sign in
        await ref
            .read(authNotifierProvider.notifier)
            .signIn(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        final authState = ref.read(authNotifierProvider);

        await authState.when(
          data: (_) async {
            if (mounted) {
              // Handle post-login sync
              await _handlePostLogin();

              if (mounted) {
                // Navigate using pushAndRemoveUntil (cleaner than popUntil)
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false, // Remove all previous routes
                );

                // Show success message
                await Future.delayed(const Duration(milliseconds: 300));
                if (mounted) {
                  CustomSnackBar.showSuccess(context, 'Inloggad');
                }
              }
            }
          },
          loading: () async {},
          error: (error, _) async {
            if (mounted) {
              CustomSnackBar.showError(context, 'Inloggning misslyckades');
            }
          },
        );
      } catch (e) {
        print('❌ Sign in error: $e');
        if (mounted) {
          CustomSnackBar.showError(context, 'Något gick fel: $e');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  /// Simplified post-login with offline deletion handling
  Future<void> _handlePostLogin() async {
    try {
      final syncManager = ref.read(syncManagerProvider);
      final currentUserId = syncManager.userId;
      if (currentUserId == null) return;

      await _identifyRevenueCatUser(currentUserId);

      final isDifferentUser = UserSessionTracker.isDifferentUser(currentUserId);

      if (isDifferentUser) {
        await clearAllLocalData();
        await MaintenanceDeletionTracker.clearAll();
      } else {
        await _processOfflineMaintenanceDeletions();

        // Check if anonymous local vehicles would exceed this user's cloud limit
        await _discardAnonymousVehiclesIfOverLimit(currentUserId);
      }

      await UserSessionTracker.saveUserId(currentUserId);

      ref.invalidate(vehiclesProvider);
      ref.invalidate(maintenanceProvider);
      ref.invalidate(receiptNotifierProvider);
      ref.invalidate(premiumStatusProvider);
      ref.invalidate(supabasePremiumStatusProvider);
      ref.invalidate(combinedPremiumStatusProvider);
      ref.invalidate(premiumFeaturesProvider);
      ref.invalidate(userTierProvider);
      ref.invalidate(featureCheckerProvider);

      await ref
          .read(syncManagerProvider)
          .performFullSyncWithUI(context, ref, showLoadingDialog: false);
    } catch (e) {
      print('❌ Error during post-login: $e');
      rethrow;
    }
  }

  Future<void> _discardAnonymousVehiclesIfOverLimit(String userId) async {
    try {
      final cloudResponse = await Supabase.instance.client
          .from('vehicles')
          .select('id')
          .eq('user_id', userId);
      final cloudCount = (cloudResponse as List).length;

      if (cloudCount == 0) return;

      final checker = ref.read(featureCheckerProvider);
      if (!checker.canAddVehicle(cloudCount)) {
        final anonymousVehicles = StorageService.getAllVehicles()
            .where((v) => v.userId == null || v.userId!.isEmpty)
            .toList();

        for (final vehicle in anonymousVehicles) {
          await StorageService.deleteVehicle(vehicle.id);
        }

        if (anonymousVehicles.isNotEmpty && mounted) {
          CustomSnackBar.showInfo(
            context,
            'Lokalt fordon togs bort — du har redan nått gränsen för din plan.',
          );
        }
      }
    } catch (e) {
      // Non-fatal — let sync proceed even if this check fails
    }
  }

  Future<void> _identifyRevenueCatUser(String supabaseUserId) async {
    try {
      await Purchases.logIn(supabaseUserId);

      ref.invalidate(premiumStatusProvider);
      ref.invalidate(combinedPremiumStatusProvider);
    } catch (e) {
      print('⚠️ Error identifying RevenueCat user: $e');
    }
  }

  /// Process maintenance records deleted while offline
  Future<void> _processOfflineMaintenanceDeletions() async {
    final deletedRecordIds = MaintenanceDeletionTracker.getDeletedRecords();

    if (deletedRecordIds.isEmpty) {
      return;
    }

    final syncService = SyncService();

    for (final recordId in deletedRecordIds) {
      try {
        // Delete from cloud (if it exists there)
        await syncService.deleteMaintenanceRecord(recordId);
      } catch (e) {
        print('⚠️ Could not delete maintenance from cloud: $recordId - $e');
        // Continue anyway - record is already deleted locally
      }
    }

    // Clear deletion tracker
    await MaintenanceDeletionTracker.clearDeletedRecords();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading || _isProcessing;

    return Scaffold(
      appBar: AppBar(title: const Text('Logga in')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Logo/Title
                Text(
                  'AUTIVO',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.tertiary,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Synkronisera din fordonshistorik',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),

                const SizedBox(height: 60),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-post',
                    hintText: 'din@email.com',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ange e-postadress';
                    }
                    if (!value.contains('@')) {
                      return 'Ange giltig e-postadress';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Lösenord',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  onFieldSubmitted: (_) => _signIn(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ange lösenord';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Sign in button
                ElevatedButton(
                  onPressed: isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Logga in'),
                ),

                const SizedBox(height: 16),

                // Forgot password
                TextButton(
                  onPressed: isLoading ? null : () => _showForgotPassword(),
                  child: const Text('Glömt lösenord?'),
                ),

                const SizedBox(height: 40),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'eller',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 24),

                // Sign up button
                OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Skapa konto'),
                ),

                const SizedBox(height: 24),

                // Continue without account
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeScreen(),
                          ),
                        ),
                  child: const Text('Fortsätt utan konto'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Återställ lösenord'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ange din e-postadress så skickar vi en länk för att återställa ditt lösenord.',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'E-post',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_emailController.text.isNotEmpty) {
                await ref
                    .read(authNotifierProvider.notifier)
                    .resetPassword(_emailController.text.trim());

                if (mounted) {
                  Navigator.pop(context);
                  CustomSnackBar.showInfo(
                    context,
                    'Återställningslänk skickad!!',
                  );
                }
              }
            },
            child: const Text('Skicka'),
          ),
        ],
      ),
    );
  }
}
