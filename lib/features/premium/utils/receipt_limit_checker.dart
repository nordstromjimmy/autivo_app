import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../premium/providers/combined_premium_provider.dart';
import '../../receipts/repositories/receipt_repository.dart';

class ReceiptLimitChecker {
  static const int freeReceiptLimit = 3;

  /// Check if user can add more receipts
  static bool canAddReceipt(WidgetRef ref) {
    // Premium users have unlimited receipts
    final isPremium = ref.watch(combinedPremiumStatusProvider).value ?? false;
    if (isPremium) return true;

    // Free users (logged in OR out) limited to 3
    final repo = ReceiptRepository();
    final currentCount = repo.getAll().length;

    return currentCount < freeReceiptLimit;
  }

  /// Get current receipt count
  static int getCurrentCount(WidgetRef ref) {
    final repo = ReceiptRepository();
    return repo.getAll().length;
  }

  /// Get remaining receipt slots for free users
  static int getRemainingSlots(WidgetRef ref) {
    final isPremium = ref.watch(combinedPremiumStatusProvider).value ?? false;
    if (isPremium) return -1; // Unlimited

    final currentCount = getCurrentCount(ref);
    return (freeReceiptLimit - currentCount).clamp(0, freeReceiptLimit);
  }
}

// Provider for easy access
final canAddReceiptProvider = Provider<bool>((ref) {
  return ReceiptLimitChecker.canAddReceipt(ref as WidgetRef);
});

final remainingReceiptsProvider = Provider<int>((ref) {
  return ReceiptLimitChecker.getRemainingSlots(ref as WidgetRef);
});
