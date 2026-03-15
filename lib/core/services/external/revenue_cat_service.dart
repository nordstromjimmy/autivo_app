import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Service for managing RevenueCat purchases
class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  bool _isInitialized = false;

  /// Initialize RevenueCat SDK
  /// Call this once in main.dart before runApp()
  Future<void> initialize(String apiKey) async {
    if (_isInitialized) return;

    await Purchases.setLogLevel(LogLevel.debug);

    final configuration = PurchasesConfiguration(apiKey);
    await Purchases.configure(configuration);

    _isInitialized = true;
  }

  /// Check if user has premium entitlement
  Future<bool> isPremium() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all['premium']?.isActive ?? false;
    } catch (e) {
      // If error, assume not premium (fail safe)
      return false;
    }
  }

  /// Get available offerings (products to purchase)
  Future<Offerings?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings;
    } catch (e) {
      print('Error fetching offerings: $e');
      return null;
    }
  }

  /// Purchase a package
  Future<PurchaseResult> purchasePackage(Package package) async {
    try {
      final purchaseResult = await Purchases.purchasePackage(package);
      final customerInfo = purchaseResult.customerInfo;
      final isPremium =
          customerInfo.entitlements.all['premium']?.isActive ?? false;

      return PurchaseResult(success: isPremium, customerInfo: customerInfo);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);

      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseResult(success: false, error: 'Köp avbrutet');
      } else if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        return PurchaseResult(success: true, error: 'Redan köpt');
      } else {
        return PurchaseResult(
          success: false,
          error: 'Köp misslyckades: ${e.message}',
        );
      }
    } catch (e) {
      return PurchaseResult(success: false, error: 'Oväntat fel: $e');
    }
  }

  /// Restore previous purchases
  Future<PurchaseResult> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      final isPremium =
          customerInfo.entitlements.all['premium']?.isActive ?? false;

      return PurchaseResult(
        success: isPremium,
        customerInfo: customerInfo,
        message: isPremium ? 'Premium återställt!' : 'Inga köp hittades',
      );
    } catch (e) {
      return PurchaseResult(
        success: false,
        error: 'Kunde inte återställa köp: $e',
      );
    }
  }

  /// Get customer info (for debugging)
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      print('Error fetching customer info: $e');
      return null;
    }
  }
}

/// Result of a purchase or restore operation
class PurchaseResult {
  final bool success;
  final String? error;
  final String? message;
  final CustomerInfo? customerInfo;

  PurchaseResult({
    required this.success,
    this.error,
    this.message,
    this.customerInfo,
  });
}
