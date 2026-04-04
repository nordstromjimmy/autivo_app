import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mina_fordon/features/auth/screens/sign_in_screen.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/services/storage/storage_service.dart';
import '../../../core/utils/tracking/clear_local_data.dart';
import '../../receipts/providers/receipt_provider.dart';
import '../providers/auth_provider.dart';
import '../../maintenance/providers/maintenance_provider.dart';
import '../../premium/providers/purchase_provider.dart';
import '../../premium/providers/combined_premium_provider.dart';
import '../../vehicles/providers/vehicle_provider.dart';
import '../../../core/services/sync/sync_manager.dart';
import '../../../core/utils/helpers/custom_snackbar.dart';
import '../../premium/utils/feature_checker.dart';
import '../../premium/utils/premium_features.dart';
import '../../../core/services/auth/user_session_tracker.dart';
import '../../../screens/home_screen.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isProcessing = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate() && !_isProcessing) {
      setState(() {
        _isProcessing = true;
      });

      try {
        // Show migration info if there's local data
        final syncManager = ref.read(syncManagerProvider);
        if (syncManager.hasLocalDataToMigrate()) {
          final confirm = await _showMigrationDialog();
          if (confirm != true) {
            setState(() {
              _isProcessing = false;
            });
            return;
          }
        }

        // Sign up
        await ref
            .read(authNotifierProvider.notifier)
            .signUp(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );

        final authState = ref.read(authNotifierProvider);

        await authState.when(
          data: (_) async {
            if (mounted) {
              // Handle post-signup (sync data, migrate local vehicles)
              await _handlePostSignup();

              if (mounted) {
                // Navigate using pushAndRemoveUntil (same as sign in)
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false, // Remove all previous routes
                );

                // Show success message
                await Future.delayed(const Duration(milliseconds: 300));
                if (mounted) {
                  CustomSnackBar.showSuccess(context, 'Konto skapat!');
                }
              }
            }
          },
          loading: () async {},
          error: (error, _) async {
            if (mounted) {
              CustomSnackBar.showError(context, 'Registreringen misslyckades');
            }
          },
        );
      } catch (e) {
        print('❌ Sign up error: $e');
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

  /// Handle post-signup setup (similar to post-login)
  Future<void> _handlePostSignup() async {
    try {
      final syncManager = ref.read(syncManagerProvider);
      final currentUserId = syncManager.userId;
      if (currentUserId == null) return;

      await _identifyRevenueCatUser(currentUserId);

      // If local data belongs to a different previous user, clear it first
      // before sync so we don't accidentally upload their data
      final localVehicles = StorageService.getAllVehicles();
      final hasOtherUserData = localVehicles.any(
        (v) =>
            v.userId != null &&
            v.userId!.isNotEmpty &&
            v.userId != currentUserId,
      );

      if (hasOtherUserData) {
        await clearAllLocalData();
      }

      await UserSessionTracker.saveUserId(currentUserId);

      // Invalidate providers first
      ref.invalidate(vehiclesProvider);
      ref.invalidate(maintenanceProvider);
      ref.invalidate(receiptNotifierProvider);
      ref.invalidate(premiumStatusProvider);
      ref.invalidate(supabasePremiumStatusProvider);
      ref.invalidate(combinedPremiumStatusProvider);
      ref.invalidate(premiumFeaturesProvider);
      ref.invalidate(userTierProvider);
      ref.invalidate(featureCheckerProvider);

      // Sync pulls the new user's cloud data (empty for new accounts)
      // and uploads any anonymous local data the user had before signing up.
      // This is what makes the UI correct without a manual refresh.
      await syncManager.performFullSyncWithUI(
        context,
        ref,
        showLoadingDialog: false,
      );
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, 'Något gick fel vid registrering');
      }
      rethrow;
    }
  }

  Future<void> _identifyRevenueCatUser(String supabaseUserId) async {
    try {
      // Link RevenueCat user to Supabase user ID
      await Purchases.logIn(supabaseUserId);

      // Invalidate premium providers to refresh
      ref.invalidate(premiumStatusProvider);
      ref.invalidate(combinedPremiumStatusProvider);
    } catch (e) {
      print('⚠️ Error identifying RevenueCat user: $e');
      // Don't throw - continue even if RevenueCat fails
    }
  }

  Future<bool?> _showMigrationDialog() {
    final syncManager = ref.read(syncManagerProvider);
    final count = syncManager.totalPendingCount;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Synkronisera data?'),
        content: Text(
          'Du har $count fordon/poster som kommer synkroniseras till molnet när du skapar konto. Din data kommer vara tillgänglig på alla dina enheter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Skapa konto'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading || _isProcessing;

    return Scaffold(
      appBar: AppBar(title: const Text('Skapa konto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Title
                Text(
                  'Kom igång',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Skapa ett konto för att synkronisera din fordonshistorik',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),

                const SizedBox(height: 40),

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
                    hintText: 'Minst 6 tecken',
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
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ange lösenord';
                    }
                    if (value.length < 6) {
                      return 'Lösenordet måste vara minst 6 tecken';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Bekräfta lösenord',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  onFieldSubmitted: (_) => _signUp(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bekräfta lösenord';
                    }
                    if (value != _passwordController.text) {
                      return 'Lösenorden matchar inte';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Sign up button
                ElevatedButton(
                  onPressed: isLoading ? null : _signUp,
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
                      : const Text('Skapa konto'),
                ),
                const SizedBox(height: 40),
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
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignInScreen(),
                            ),
                          );
                        },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Logga in'),
                ),

                const SizedBox(height: 24),

                // Benefits card
                Card(
                  color: Theme.of(context).colorScheme.secondary,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.cloud,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Med ett konto får du:',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildBenefit(
                          icon: Icons.backup,
                          text: 'Molnbackup av all data',
                        ),
                        _buildBenefit(
                          icon: Icons.devices,
                          text: 'Synkronisera mellan enheter',
                        ),
                        _buildBenefit(
                          icon: Icons.security,
                          text: 'Säker lagring',
                        ),
                        _buildBenefit(
                          icon: Icons.history,
                          text: 'Aldrig förlora din historik',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
