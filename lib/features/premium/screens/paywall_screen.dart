import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/purchase_provider.dart';
import '../../../core/utils/helpers/custom_snackbar.dart';
import '../utils/premium_features.dart';
import '../../auth/screens/sign_up_screen.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  Offerings? _offerings;
  bool _isLoading = true;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final service = ref.read(revenueCatServiceProvider);
    final offerings = await service.getOfferings();

    setState(() {
      _offerings = offerings;
      _isLoading = false;
    });
  }

  /// Check if user has an account (logged into Supabase)
  bool get _hasAccount {
    final user = Supabase.instance.client.auth.currentUser;
    return user != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _offerings == null
          ? _buildErrorView()
          : _buildPaywallContent(),
    );
  }

  Widget _buildErrorView() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Kunde inte ladda produkter',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() => _isLoading = true);
                _loadOfferings();
              },
              child: const Text('Försök igen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaywallContent() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final offering = _offerings!.current;
    if (offering == null) {
      return _buildErrorView();
    }

    final package = offering.availablePackages.firstOrNull;
    if (package == null) {
      return _buildErrorView();
    }

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji - fixed size
                  const Padding(
                    padding: EdgeInsets.only(
                      top: 4,
                    ), // Align with text baseline
                    child: Text('✨', style: TextStyle(fontSize: 36)),
                  ),
                  const SizedBox(width: 12),

                  // Text - flexible, wraps on small screens
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Uppgradera till',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Premium',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Lås upp alla funktioner med ett engångsköp',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 40),

              // Features list
              _buildFeatureItem(
                context,
                icon: Icons.directions_car,
                title: 'Obegränsat antal fordon',
                description: 'Hantera hur många bilar du vill',
              ),
              _buildFeatureItem(
                context,
                icon: Icons.cloud_done,
                title: 'Molnsynkronisering',
                description: 'Säkerhetskopiera automatiskt till molnet',
                requiresAccount: true,
              ),
              _buildFeatureItem(
                context,
                icon: Icons.document_scanner,
                title: 'OCR-verifiering',
                description: 'Verifiera fordon med registreringsbevis',
                requiresAccount: true,
              ),
              _buildFeatureItem(
                context,
                icon: Icons.picture_as_pdf,
                title: 'Professionella PDF-exporter',
                description: 'Exportera utan vattenstämpel',
              ),
              _buildFeatureItem(
                context,
                icon: Icons.analytics,
                title: 'Kostnadsanalys',
                description: 'Detaljerad statistik och trender',
              ),
              _buildFeatureItem(
                context,
                icon: Icons.camera_alt,
                title: 'Kvittofoton',
                description: 'Bifoga kvitton och dokument',
                requiresAccount: true,
              ),
              _buildFeatureItem(
                context,
                icon: Icons.file_download,
                title: 'Excel-export',
                description: 'Exportera data till Excel/CSV',
              ),
              _buildFeatureItem(
                context,
                icon: Icons.priority_high,
                title: 'Prioriterad support',
                description: 'Få hjälp snabbare via e-post',
              ),

              const SizedBox(height: 40),

              // Price card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF64B5F6), const Color(0xFF42A5F5)]
                        : [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.8),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          package.storeProduct.priceString,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Engångsbetalning • Ägs för alltid',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.black87 : Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Purchase button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isPurchasing
                      ? null
                      : () => _handlePurchase(package),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? const Color(0xFF64B5F6)
                        : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isPurchasing
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          _hasAccount ? 'Köp Premium' : 'Skapa konto först',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Restore button
              Center(
                child: TextButton(
                  onPressed: _isPurchasing ? null : _restorePurchases,
                  child: Text(
                    'Återställ tidigare köp',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Fine print
              Text(
                'Betalningen dras från ditt Google Play-konto. Inga dolda avgifter eller prenumerationer. Du äger Premium för alltid.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    bool requiresAccount = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF64B5F6).withValues(alpha: 0.2)
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isDark
                  ? const Color(0xFF64B5F6)
                  : theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase(Package package) async {
    // Check if user has account
    if (!_hasAccount) {
      //Navigator.pop(context); // Close paywall
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignUpScreen()),
      );
      return;
    }

    // Proceed with purchase
    await _purchase(package);
  }

  Future<void> _purchase(Package package) async {
    setState(() => _isPurchasing = true);

    final service = ref.read(revenueCatServiceProvider);
    final result = await service.purchasePackage(package);

    setState(() => _isPurchasing = false);

    if (!mounted) return;

    if (result.success) {
      // Refresh premium status from RevenueCat
      ref.read(premiumStatusProvider.notifier).refresh();

      // Sync premium status to Supabase
      try {
        final premiumFeatures = ref.read(premiumFeaturesProvider);
        await premiumFeatures.syncPremiumToSupabase();
      } catch (e) {
        print('Failed to sync premium to Supabase: $e');
        // Don't block user flow if Supabase sync fails
      }

      CustomSnackBar.showSuccess(context, '🎉 Premium upplåst!');
      Navigator.pop(context, true);
    } else {
      if (result.error != null && !result.error!.contains('avbrutet')) {
        CustomSnackBar.showError(context, result.error!);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isPurchasing = true);

    final service = ref.read(revenueCatServiceProvider);
    final result = await service.restorePurchases();

    setState(() => _isPurchasing = false);

    if (!mounted) return;

    if (result.success) {
      // Refresh premium status
      ref.read(premiumStatusProvider.notifier).refresh();

      CustomSnackBar.showSuccess(
        context,
        result.message ?? 'Premium återställt!',
      );
      Navigator.pop(context, true);
    } else {
      CustomSnackBar.showError(
        context,
        result.error ?? 'Inga tidigare köp hittades',
      );
    }
  }
}
