import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/vehicles/models/vehicle.dart';
import '../../../features/maintenance/providers/maintenance_provider.dart';
import '../../../features/receipts/providers/receipt_provider.dart';
import '../../../features/premium/utils/feature_checker.dart';
import '../../../features/premium/utils/feature_gates.dart';
import '../../../features/premium/screens/paywall_screen.dart';
import '../../../core/utils/helpers/custom_snackbar.dart';
import '../../../shared/widgets/pdf_preview_screen.dart';

class PdfExportHelper {
  /// Export vehicle PDF with premium check
  static Future<void> exportVehiclePDF({
    required BuildContext context,
    required WidgetRef ref,
    required Vehicle vehicle,
  }) async {
    // Check if user can export PDF
    final checker = ref.read(featureCheckerProvider);
    // TODO remove comments to make it require premium again
    //final canExportPDF = checker.canUse(AppFeature.exportMaintenancePDF);
    final canExportPDF = true;

    if (!canExportPDF) {
      _showPremiumRequired(context, ref, checker);
      return;
    }

    // User has premium - proceed with export
    await _performExport(context, ref, vehicle);
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

    // ✅ Navigate to preview screen instead of generating immediately
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
