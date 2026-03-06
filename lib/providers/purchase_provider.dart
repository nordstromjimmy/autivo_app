import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/revenue_cat_service.dart';

/// Provider for RevenueCat service instance
final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService();
});

/// Provider to check if user has premium
/// This is used throughout the app to gate features
final isPremiumProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(revenueCatServiceProvider);
  return await service.isPremium();
});

/// Provider that watches premium status and auto-refreshes
final premiumStatusProvider =
    StateNotifierProvider<PremiumStatusNotifier, AsyncValue<bool>>((ref) {
      return PremiumStatusNotifier(ref);
    });

/// Notifier to manage premium status with refresh capability
class PremiumStatusNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref ref;

  PremiumStatusNotifier(this.ref) : super(const AsyncValue.loading()) {
    checkStatus();
  }

  /// Check premium status
  Future<void> checkStatus() async {
    state = const AsyncValue.loading();
    try {
      final service = ref.read(revenueCatServiceProvider);
      final isPremium = await service.isPremium();
      state = AsyncValue.data(isPremium);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh premium status (call after purchase/restore)
  Future<void> refresh() async {
    await checkStatus();
  }
}
