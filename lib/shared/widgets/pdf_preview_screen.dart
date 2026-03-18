import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../../features/vehicles/models/vehicle.dart';
import '../../../features/maintenance/models/maintenance_record.dart';
import '../../../features/receipts/models/receipt.dart';
import '../../../core/services/media/pdf_export_service.dart';

class PdfPreviewScreen extends StatelessWidget {
  final Vehicle vehicle;
  final List<MaintenanceRecord> records;
  final List<Receipt>? receipts;

  const PdfPreviewScreen({
    super.key,
    required this.vehicle,
    required this.records,
    this.receipts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Förhandsgranska PDF'),
        actions: [
          // Info button
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Information',
            onPressed: () => _showInfo(context),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(format),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        // Customize action buttons
        actions: [
          // Share button
          PdfPreviewAction(icon: const Icon(Icons.share), onPressed: _sharePdf),
          // Download button
          PdfPreviewAction(
            icon: const Icon(Icons.download),
            onPressed: _downloadPdf,
          ),
        ],
        // Loading message
        loadingWidget: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Genererar förhandsgranskning...'),
                ],
              ),
            ),
          ),
        ),

        // Page format
        pageFormats: const {'A4': PdfPageFormat.a4},
      ),
    );
  }

  /// Generate the PDF document
  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    // Use the existing service to generate PDF
    final file = await PdfExportService.generateMaintenancePDF(
      vehicle: vehicle,
      records: records,
      receipts: receipts,
    );

    return await file.readAsBytes();
  }

  /// Share the PDF
  Future<void> _sharePdf(
    BuildContext context,
    LayoutCallback build,
    PdfPageFormat format,
  ) async {
    try {
      // Generate PDF
      final bytes = await build(format);

      // Share using the PDF service
      await Printing.sharePdf(bytes: bytes, filename: _getFileName());
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fel vid delning: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Download/save the PDF
  Future<void> _downloadPdf(
    BuildContext context,
    LayoutCallback build,
    PdfPageFormat format,
  ) async {
    try {
      // Show loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Sparar PDF...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Generate PDF
      final bytes = await build(format);

      // Save to device
      final saved = await Printing.layoutPdf(onLayout: (format) async => bytes);

      // Close loading
      if (context.mounted) Navigator.pop(context);

      // Show success
      if (context.mounted && saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ PDF sparad'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Close loading
      if (context.mounted) Navigator.pop(context);

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fel vid sparande: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show info dialog about what's included
  void _showInfo(BuildContext context) {
    final receiptCount = receipts?.length ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Om rapporten'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Denna rapport innehåller:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(Icons.directions_car, 'Fordonsuppgifter'),
            _buildInfoItem(Icons.assessment, 'Statistik & översikt'),
            _buildInfoItem(
              Icons.build,
              '${records.length} ${records.length == 1 ? 'servicepost' : 'serviceposter'}',
            ),
            if (receiptCount > 0)
              _buildInfoItem(
                Icons.receipt,
                '$receiptCount ${receiptCount == 1 ? 'kvitto' : 'kvitton'}',
              ),
            const SizedBox(height: 16),
            Text(
              'Format: A4 PDF',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  /// Generate filename
  String _getFileName() {
    final timestamp = DateTime.now();
    return 'Servicehistorik_${vehicle.registrationNumber}_${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}.pdf';
  }
}
