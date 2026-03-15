import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/paywall_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../utils/feature_checker.dart';
import '../utils/feature_gates.dart';

class FeatureGate extends ConsumerWidget {
  final AppFeature feature;
  final Widget child;
  final Widget? fallback;
  final bool showLock;

  const FeatureGate({
    super.key,
    required this.feature,
    required this.child,
    this.fallback,
    this.showLock = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checker = ref.watch(featureCheckerProvider);

    if (checker.canUse(feature)) {
      return child;
    }

    // User doesn't have access - show fallback or upgrade prompt
    return fallback ?? _buildUpgradePrompt(context, checker);
  }

  Widget _buildUpgradePrompt(BuildContext context, FeatureChecker checker) {
    if (!showLock) {
      return const SizedBox.shrink();
    }

    final requiredTier = checker.getRequiredTier(feature);

    return Opacity(
      opacity: 0.5,
      child: Stack(
        children: [
          IgnorePointer(child: child),
          Positioned.fill(
            child: InkWell(
              onTap: () => _showUpgradeDialog(context, checker, requiredTier),
              child: Center(
                child: Icon(Icons.lock, color: Colors.grey[600], size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(
    BuildContext context,
    FeatureChecker checker,
    UserTier? requiredTier,
  ) {
    final featureName = FeatureMetadata.getDisplayName(feature);
    final message = checker.getUpgradeMessage(feature);
    final cta = checker.getUpgradeCTA(feature);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_open, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Expanded(child: Text(featureName)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Text(
              FeatureMetadata.getDescription(feature),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avbryt'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (requiredTier == UserTier.free) {
                // Need account - show signup
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignUpScreen()),
                );
              } else if (requiredTier == UserTier.premium) {
                // Need premium - show paywall
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PaywallScreen(),
                  ),
                );
              }
            },
            child: Text(cta),
          ),
        ],
      ),
    );
  }
}

/// Simplified feature gate that just hides content if not available
class FeatureHide extends ConsumerWidget {
  final AppFeature feature;
  final Widget child;

  const FeatureHide({super.key, required this.feature, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checker = ref.watch(featureCheckerProvider);

    if (!checker.canUse(feature)) {
      return const SizedBox.shrink();
    }

    return child;
  }
}

/// Show content ONLY if feature is locked (opposite of FeatureHide)
class FeatureShowIfLocked extends ConsumerWidget {
  final AppFeature feature;
  final Widget child;

  const FeatureShowIfLocked({
    super.key,
    required this.feature,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checker = ref.watch(featureCheckerProvider);

    if (checker.canUse(feature)) {
      return const SizedBox.shrink();
    }

    return child;
  }
}
