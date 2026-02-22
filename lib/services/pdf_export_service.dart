import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../models/maintenance_record.dart';
import '../models/vehicle.dart';

class PdfExportService {
  // Colors matching app theme
  static const primaryColor = PdfColor.fromInt(0xFF2196F3); // Blue
  static const secondaryColor = PdfColor.fromInt(0xFF757575); // Gray
  static const whiteColor = PdfColor.fromInt(0xFFFFFFFF); // white
  static const accentGreen = PdfColor.fromInt(0xFF4CAF50);
  static const accentOrange = PdfColor.fromInt(0xFFFF9800);
  static const accentBlue = PdfColor.fromInt(0xFF2196F3);
  static const accentPurple = PdfColor.fromInt(0xFF9C27B0);

  static Future<File> generateMaintenancePDF({
    required Vehicle vehicle,
    required List<MaintenanceRecord> records,
  }) async {
    final pdf = pw.Document();

    // Page 1: Cover Page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) => _buildCoverPage(vehicle),
      ),
    );

    // Page 2: Summary & Statistics
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => _buildSummaryPage(vehicle, records),
      ),
    );

    // Page 3+: Maintenance History
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [_buildMaintenanceHistory(records)],
        footer: (context) => _buildPageFooter(context),
      ),
    );

    // Save PDF
    final output = await getTemporaryDirectory();
    final timestamp = DateTime.now();
    final fileName =
        'Servicehistorik_${vehicle.registrationNumber}_${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  // ==================== COVER PAGE ====================
  static pw.Widget _buildCoverPage(Vehicle vehicle) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [primaryColor, PdfColor.fromInt(0xFF1976D2)],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
      ),
      child: pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            // Autivo Logo/Branding
            pw.Text(
              'AUTIVO',
              style: pw.TextStyle(
                fontSize: 48,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                letterSpacing: 4,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Fullständig Fordonshistorik',
              style: const pw.TextStyle(
                fontSize: 16,
                color: PdfColors.white,
                letterSpacing: 1,
              ),
            ),

            pw.SizedBox(height: 60),

            // Vehicle Icon Placeholder
            pw.Container(
              width: 120,
              height: 120,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(60),
              ),
              child: pw.Center(
                child: pw.Icon(
                  pw.IconData(0xe531), // car icon
                  size: 60,
                  color: primaryColor,
                ),
              ),
            ),

            pw.SizedBox(height: 40),

            // Registration Number - Large
            pw.Text(
              vehicle.registrationNumber,
              style: pw.TextStyle(
                fontSize: 56,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                letterSpacing: 4,
              ),
            ),

            pw.SizedBox(height: 16),

            // Make Model Year
            pw.Text(
              '${vehicle.make} ${vehicle.model} ${vehicle.year}',
              style: const pw.TextStyle(fontSize: 24, color: PdfColors.white),
            ),

            pw.SizedBox(height: 8),

            // Verification Badge
            if (vehicle.isVerified)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: pw.BoxDecoration(
                  color: _getVerificationColor(vehicle.verificationLevel),
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  vehicle.verificationBadge,
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.white,
                  ),
                ),
              ),

            pw.Spacer(),

            // Generation Date
            pw.Text(
              'Genererad ${_formatDate(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.white),
            ),
            pw.SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ==================== SUMMARY PAGE ====================
  static pw.Widget _buildSummaryPage(
    Vehicle vehicle,
    List<MaintenanceRecord> records,
  ) {
    final totalCost = records
        .where((r) => r.cost != null)
        .fold<double>(0, (sum, r) => sum + r.cost!);

    final thisYearRecords = records
        .where((r) => r.date.year == DateTime.now().year)
        .toList();

    final thisYearCost = thisYearRecords
        .where((r) => r.cost != null)
        .fold<double>(0, (sum, r) => sum + r.cost!);

    final serviceCount = records.where((r) => r.type == 'service').length;
    final partsCount = records.where((r) => r.type == 'parts').length;
    final besiktningCount = records.where((r) => r.type == 'besiktning').length;

    return pw.Padding(
      padding: const pw.EdgeInsets.all(30),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Text(
            'Översikt',
            style: pw.TextStyle(
              fontSize: 32,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(height: 3, width: 60, color: primaryColor),
          pw.SizedBox(height: 30),

          // Statistics Cards
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard(
                'Totala poster',
                '${records.length}',
                'st',
                PdfColors.blue,
              ),
              pw.SizedBox(width: 4),
              _buildStatCard(
                'Total kostnad',
                totalCost.toStringAsFixed(0),
                'kr',
                PdfColors.green,
              ),
              pw.SizedBox(width: 4),
              _buildStatCard(
                'Senaste året',
                thisYearCost.toStringAsFixed(0),
                'kr',
                PdfColors.orange,
              ),
            ],
          ),

          pw.SizedBox(height: 30),

          // Type Breakdown
          pw.Text(
            'Fördelning',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildTypeCount('Service', serviceCount, accentBlue),
              _buildTypeCount('Reparationer', partsCount, accentOrange),
              _buildTypeCount('Besiktningar', besiktningCount, accentGreen),
            ],
          ),

          pw.SizedBox(height: 30),

          // Vehicle Details
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Fordonsuppgifter',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                _buildDetailRow(
                  'Registreringsnummer',
                  vehicle.registrationNumber,
                ),
                _buildDetailRow('Märke', vehicle.make),
                _buildDetailRow('Modell', vehicle.model),
                _buildDetailRow('Årsmodell', vehicle.year.toString()),
                if (vehicle.fuelType != null)
                  _buildDetailRow('Bränsle', vehicle.fuelType!),
                if (vehicle.currentMileage != null)
                  _buildDetailRow(
                    'Mätarställning',
                    '${vehicle.currentMileage.toString()} km',
                  ),
                if (vehicle.ownershipStartDate != null)
                  _buildDetailRow(
                    'Ägare sedan',
                    _formatDate(vehicle.ownershipStartDate!),
                  ),
                if (vehicle.nextBesiktningDate != null)
                  _buildDetailRow(
                    'Nästa besiktning',
                    _formatDate(vehicle.nextBesiktningDate!),
                  ),
              ],
            ),
          ),

          pw.Spacer(),

          // Placeholder for future chart
          pw.Container(
            height: 150,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Center(
              child: pw.Text(
                'Kostnadsöversikt - Funktion kommer snart',
                style: pw.TextStyle(
                  fontSize: 14,
                  color: secondaryColor,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== MAINTENANCE HISTORY ====================
  static pw.Widget _buildMaintenanceHistory(List<MaintenanceRecord> records) {
    // Group by year
    final groupedByYear = <int, List<MaintenanceRecord>>{};
    for (var record in records) {
      groupedByYear.putIfAbsent(record.date.year, () => []).add(record);
    }

    final sortedYears = groupedByYear.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Servicehistorik',
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(height: 3, width: 60, color: primaryColor),
            ],
          ),
        ),

        // Records by year
        ...sortedYears.map((year) {
          final yearRecords = groupedByYear[year]!;
          final yearCost = yearRecords
              .where((r) => r.cost != null)
              .fold<double>(0, (sum, r) => sum + r.cost!);

          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Year header
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '$year',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      pw.Text(
                        'Totalt: ${yearCost.toStringAsFixed(0)} kr',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),

                // Table
                _buildMaintenanceTable(yearRecords),
                pw.SizedBox(height: 24),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildMaintenanceTable(List<MaintenanceRecord> records) {
    // Sort by date descending
    final sortedRecords = List<MaintenanceRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.1), // Date
        1: const pw.FlexColumnWidth(1.3), // Type
        2: const pw.FlexColumnWidth(
          3.0,
        ), // Description (increased for longer text)
        3: const pw.FlexColumnWidth(1.9), // Location
        4: const pw.FlexColumnWidth(1.4), // Mileage
        5: const pw.FlexColumnWidth(1.3), // Cost
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableHeader('Datum'),
            _buildTableHeader('Typ'),
            _buildTableHeader('Beskrivning'),
            _buildTableHeader('Plats'),
            _buildTableHeader('Mätarst.'),
            _buildTableHeader('Kostnad'),
          ],
        ),
        // Data rows
        ...sortedRecords.asMap().entries.map((entry) {
          final index = entry.key;
          final record = entry.value;
          final isEven = index % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : PdfColors.grey50,
            ),
            children: [
              _buildTableCell(_formatDate(record.date)),
              _buildTableCell(
                _getTypeLabel(record.type),
                color: _getTypeColor(record.type),
              ),
              _buildTableCell(record.description),
              _buildTableCell(record.location ?? '-'),
              _buildTableCell(
                record.mileage != null ? '${record.mileage} km' : '-',
              ),
              _buildTableCell(
                record.cost != null
                    ? '${record.cost!.toStringAsFixed(0)} kr'
                    : '-',
              ),
            ],
          );
        }),
      ],
    );
  }

  // ==================== HELPER WIDGETS ====================
  static pw.Widget _buildStatCard(
    String label,
    String value,
    String unit,
    PdfColor color,
  ) {
    return pw.Container(
      width: 150,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: color.shade(0.9),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 12, color: whiteColor)),
          pw.SizedBox(height: 8),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: whiteColor,
                ),
              ),
              pw.SizedBox(width: 4),
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  unit,
                  style: pw.TextStyle(fontSize: 14, color: whiteColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTypeCount(String label, int count, PdfColor color) {
    return pw.Column(
      children: [
        pw.Container(
          width: 50,
          height: 50,
          decoration: pw.BoxDecoration(
            color: color.shade(0.9),
            shape: pw.BoxShape.circle,
          ),
          child: pw.Center(
            child: pw.Text(
              '$count',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: whiteColor,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(label, style: const pw.TextStyle(fontSize: 12)),
      ],
    );
  }

  static pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 150,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 12, color: secondaryColor),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        softWrap: true,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, color: color),
        softWrap: true,
        maxLines: null, // Allow unlimited lines for wrapping
      ),
    );
  }

  static pw.Widget _buildPageFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Genererad med Autivo',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Sida ${context.pageNumber} av ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER METHODS ====================
  static PdfColor _getVerificationColor(String level) {
    switch (level) {
      case 'self':
        return PdfColors.orange;
      case 'sms':
        return PdfColors.blue;
      case 'official':
        return PdfColors.green;
      default:
        return PdfColors.grey;
    }
  }

  static String _getTypeLabel(String type) {
    switch (type) {
      case 'service':
        return 'Service';
      case 'parts':
        return 'Reparation';
      case 'besiktning':
        return 'Besiktning';
      case 'other':
        return 'Annat';
      default:
        return type;
    }
  }

  static PdfColor _getTypeColor(String type) {
    switch (type) {
      case 'service':
        return accentBlue;
      case 'parts':
        return accentOrange;
      case 'besiktning':
        return accentGreen;
      case 'other':
        return accentPurple;
      default:
        return secondaryColor;
    }
  }

  static String _formatDate(DateTime date) {
    const months = [
      'jan',
      'feb',
      'mar',
      'apr',
      'maj',
      'jun',
      'jul',
      'aug',
      'sep',
      'okt',
      'nov',
      'dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Share the PDF using the system share sheet
  static Future<void> sharePDF(File file) async {
    await Printing.sharePdf(
      bytes: await file.readAsBytes(),
      filename: file.path.split('/').last,
    );
  }

  /// Save PDF to downloads/documents folder (platform specific)
  static Future<String> savePDF(File file) async {
    // The file is already saved to temp directory
    // This method can be extended to save to platform-specific locations
    return file.path;
  }
}
