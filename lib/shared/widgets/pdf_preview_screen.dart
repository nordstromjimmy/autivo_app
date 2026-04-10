import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../../features/vehicles/models/vehicle.dart';
import '../../../features/maintenance/models/maintenance_record.dart';
import '../../../features/receipts/models/receipt.dart';
import '../../../core/services/media/pdf_export_service.dart';
import '../../../core/services/media/share_service.dart';
import '../../../core/utils/helpers/custom_snackbar.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.link, color: Colors.blue),
            tooltip: 'Dela som länk',
            onPressed: () => _showShareLinkSheet(context),
          ),
          PdfPreviewAction(icon: const Icon(Icons.share), onPressed: _sharePdf),
          PdfPreviewAction(
            icon: const Icon(Icons.download),
            onPressed: _downloadPdf,
          ),
        ],
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
        pageFormats: const {'A4': PdfPageFormat.a4},
      ),
    );
  }

  // ==================== SHARE LINK ====================

  void _showShareLinkSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _ShareLinkSheet(
        vehicle: vehicle,
        records: records,
        receipts: receipts,
      ),
    );
  }

  // ==================== PDF ACTIONS ====================

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    final file = await PdfExportService.generateMaintenancePDF(
      vehicle: vehicle,
      records: records,
      receipts: receipts,
    );
    return await file.readAsBytes();
  }

  Future<void> _sharePdf(
    BuildContext context,
    LayoutCallback build,
    PdfPageFormat format,
  ) async {
    try {
      final bytes = await build(format);
      await Printing.sharePdf(bytes: bytes, filename: _getFileName());
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Fel vid delning: $e');
      }
    }
  }

  Future<void> _downloadPdf(
    BuildContext context,
    LayoutCallback build,
    PdfPageFormat format,
  ) async {
    try {
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

      final bytes = await build(format);
      final saved = await Printing.layoutPdf(onLayout: (format) async => bytes);

      if (context.mounted) Navigator.pop(context);

      if (context.mounted && saved) {
        CustomSnackBar.showSuccess(context, 'PDF sparad');
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        CustomSnackBar.showError(context, 'Fel vid sparande: $e');
      }
    }
  }

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
            const Text(
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

  String _getFileName() {
    final timestamp = DateTime.now();
    return 'Servicehistorik_${vehicle.registrationNumber}_${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}.pdf';
  }
}

// ==================== SHARE LINK BOTTOM SHEET ====================

class _ShareLinkSheet extends StatefulWidget {
  final Vehicle vehicle;
  final List<MaintenanceRecord> records;
  final List<Receipt>? receipts;

  const _ShareLinkSheet({
    required this.vehicle,
    required this.records,
    this.receipts,
  });

  @override
  State<_ShareLinkSheet> createState() => _ShareLinkSheetState();
}

class _ShareLinkSheetState extends State<_ShareLinkSheet> {
  final ShareService _shareService = ShareService();
  ShareReport? _report;
  bool _isLoading = true;
  bool _isCreating = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingLink();
  }

  Future<void> _loadExistingLink() async {
    setState(() => _isLoading = true);
    final report = await _shareService.getShareLink(widget.vehicle.id);
    if (mounted) {
      setState(() {
        _report = report;
        _isLoading = false;
      });
    }
  }

  Future<void> _createLink() async {
    setState(() => _isCreating = true);
    try {
      final report = await _shareService.createShareLink(
        vehicle: widget.vehicle,
        records: widget.records,
        receipts: widget.receipts,
      );
      if (mounted) {
        setState(() {
          _report = report;
          _isCreating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        CustomSnackBar.showError(context, 'Kunde inte skapa länk: $e');
      }
    }
  }

  Future<void> _deleteLink() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ta bort länk?'),
        content: const Text(
          'Länken slutar fungera omedelbart och all delad data tas bort.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ta bort'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await _shareService.deleteShareLink(widget.vehicle.id);
      if (mounted) {
        setState(() {
          _report = null;
          _isDeleting = false;
        });
        CustomSnackBar.showSuccess(context, 'Länk borttagen');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        CustomSnackBar.showError(context, 'Kunde inte ta bort länk: $e');
      }
    }
  }

  void _copyLink() {
    if (_report == null) return;
    Clipboard.setData(ClipboardData(text: _report!.shareUrl));
    CustomSnackBar.showSuccess(context, 'Länk kopierad');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Dela som länk',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Skapa en publik länk till fordonshistoriken. '
              'Perfekt att dela vid försäljning.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_report != null)
              _buildLinkExists()
            else
              _buildNoLink(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkExists() {
    final report = _report!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Link URL box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  report.shareUrl,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: _copyLink,
                tooltip: 'Kopiera länk',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Expiry info
        Row(
          children: [
            Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              'Länken är giltig i ${report.daysRemaining} dagar till',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isDeleting ? null : _deleteLink,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline, size: 18),
                label: const Text('Ta bort länk'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _copyLink,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Kopiera'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoLink() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Länken är giltig i 90 dagar och tas sedan bort automatiskt. '
                  'Du kan ta bort den manuellt när som helst.',
                  style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isCreating ? null : _createLink,
            icon: _isCreating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.link),
            label: Text(_isCreating ? 'Skapar länk...' : 'Skapa delbar länk'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
