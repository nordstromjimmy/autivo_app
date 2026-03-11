import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/combined_premium_provider.dart';

// Optional: Add this badge to your app bar or home screen header
// to show premium status at a glance

class PremiumBadge extends ConsumerWidget {
  const PremiumBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use COMBINED status (RevenueCat OR Supabase)
    final premiumStatus = ref.watch(combinedPremiumStatusProvider);

    return premiumStatus.when(
      data: (isPremium) {
        if (!isPremium) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(Icons.stars, color: Colors.white, size: 14)],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
