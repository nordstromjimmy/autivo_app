import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/premium/providers/purchase_provider.dart';
import '../../../features/vehicles/models/vehicle.dart';
import '../../../features/maintenance/providers/maintenance_provider.dart';
import '../../../features/receipts/providers/receipt_provider.dart';
import '../../../features/premium/utils/feature_checker.dart';
import '../../../features/premium/utils/feature_gates.dart';
import '../../../features/premium/screens/paywall_screen.dart';
import '../../../features/premium/providers/combined_premium_provider.dart';
import '../../../core/utils/helpers/custom_snackbar.dart';
import '../../../shared/widgets/pdf_preview_screen.dart';

class PdfExportHelper {
  /// Export vehicle PDF with premium check
  static Future<void> exportVehiclePDF({
    required BuildContext context,
    required WidgetRef ref,
    required Vehicle vehicle,
  }) async {
    // Check if premium status is still loading
    final premiumStatus = ref.read(premiumStatusProvider);
    final supabaseStatus = ref.read(supabasePremiumStatusProvider);

    final isLoading = premiumStatus.isLoading || supabaseStatus.isLoading;

    if (isLoading) {
      // Show loading dialog
      _showLoadingDialog(context);

      // Wait for both to load
      await premiumStatus.when(
        data: (_) => Future.value(),
        loading: () => Future.delayed(const Duration(milliseconds: 500)),
        error: (_, __) => Future.value(),
      );

      await supabaseStatus.when(
        data: (_) => Future.value(),
        loading: () => Future.delayed(const Duration(milliseconds: 500)),
        error: (_, __) => Future.value(),
      );

      // Close loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }
    }

    // Now check premium status
    final checker = ref.read(featureCheckerProvider);
    final canExportPDF = checker.canUse(AppFeature.exportMaintenancePDF);

    if (!canExportPDF) {
      _showPremiumRequired(context, ref, checker);
      return;
    }

    // User has premium - proceed with export
    await _performExport(context, ref, vehicle);
  }

  /// Show loading dialog
  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Kontrollerar premium-status...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show premium required dialog
  static void _showPremiumRequired(
    BuildContext context,
    WidgetRef ref,
    FeatureChecker checker,
  ) {
    final message = checker.getUpgradeMessage(AppFeature.exportMaintenancePDF);
    final cta = checker.getUpgradeCTA(AppFeature.exportMaintenancePDF);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber[900]),
            const SizedBox(width: 8),
            const Text('Premium krävs'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 16),
            Text(
              'Skapa professionella PDF-rapporter med din kompletta servicehistorik och kvitton.',
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaywallScreen()),
              );
            },
            child: Text(cta),
          ),
        ],
      ),
    );
  }

  /// Perform the actual PDF export
  static Future<void> _performExport(
    BuildContext context,
    WidgetRef ref,
    Vehicle vehicle,
  ) async {
    // Get data
    final records = ref.read(maintenanceProvider(vehicle.id));
    final receipts = ref.read(receiptsForVehicleProvider(vehicle.id));

    if (records.isEmpty && receipts.isEmpty) {
      if (context.mounted) {
        CustomSnackBar.showError(
          context,
          'Ingen data att exportera för detta fordon',
        );
      }
      return;
    }

    // Navigate to preview screen
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfPreviewScreen(
            vehicle: vehicle,
            records: records,
            receipts: receipts.isNotEmpty ? receipts : null,
          ),
        ),
      );
    }
  }
}
