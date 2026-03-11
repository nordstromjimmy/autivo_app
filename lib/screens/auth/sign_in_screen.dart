import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/purchase_provider.dart';
import '../../providers/combined_premium_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/sync_manager.dart';
import '../../services/sync_service.dart';
import '../../utils/clear_local_data.dart';
import '../../utils/custom_snackbar.dart';
import '../../utils/feature_checker.dart';
import '../../utils/maintenance_deletion_tracker.dart';
import '../../utils/premium_features.dart';
import '../../utils/user_session_tracker.dart';
import '../home_screen.dart';
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
                  CustomSnackBar.showSuccess(context, 'Inloggad!');
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

      // ✅ ADD THIS - Link RevenueCat to Supabase user
      await _identifyRevenueCatUser(currentUserId);

      final isDifferentUser = UserSessionTracker.isDifferentUser(currentUserId);

      if (isDifferentUser) {
        // DIFFERENT USER - Clear everything
        await clearAllLocalData();
        await MaintenanceDeletionTracker.clearAll();
      } else {
        // SAME USER - Process offline deletions before sync
        await _processOfflineMaintenanceDeletions();
      }

      // Save user ID
      await UserSessionTracker.saveUserId(currentUserId);

      // Sync data (merge local with cloud)
      await syncManager.fullSync();

      // Invalidate ALL providers (including feature gates)
      ref.invalidate(vehiclesProvider);
      ref.invalidate(maintenanceProvider);
      ref.invalidate(premiumStatusProvider);
      ref.invalidate(supabasePremiumStatusProvider);
      ref.invalidate(combinedPremiumStatusProvider);

      // Invalidate feature gate providers
      ref.invalidate(premiumFeaturesProvider);
      ref.invalidate(userTierProvider);
      ref.invalidate(featureCheckerProvider);
    } catch (e) {
      print('❌ Error during post-login: $e');
      rethrow;
    }
  }

  Future<void> _identifyRevenueCatUser(String supabaseUserId) async {
    try {
      await Purchases.logIn(supabaseUserId);
      print('✅ RevenueCat user identified: $supabaseUserId');

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
                  onPressed: isLoading ? null : () => Navigator.pop(context),
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
