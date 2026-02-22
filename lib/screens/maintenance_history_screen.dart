import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/maintenance_record.dart';
import '../providers/maintenance_provider.dart';
import '../providers/vehicle_provider.dart';
import '../services/pdf_export_service.dart';
import '../widgets/maintenance_list_item.dart';
import '../widgets/maintenance_summary_card.dart';

class MaintenanceHistoryScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  final String vehicleName;

  const MaintenanceHistoryScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  ConsumerState<MaintenanceHistoryScreen> createState() =>
      _MaintenanceHistoryScreenState();
}

class _MaintenanceHistoryScreenState
    extends ConsumerState<MaintenanceHistoryScreen> {
  String _filterType = 'all';
  String _sortBy = 'date_desc'; // date_desc, date_asc, cost_desc, cost_asc
  bool _isFilterExpanded = false;

  @override
  Widget build(BuildContext context) {
    final allRecords = ref.watch(maintenanceProvider(widget.vehicleId));
    final filteredRecords = _getFilteredAndSortedRecords(allRecords);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Servicehistorik'),
            Text(
              widget.vehicleName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Fler alternativ',
            onSelected: (value) {
              if (value == 'export_pdf') {
                _exportPDF();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 20),
                    SizedBox(width: 12),
                    Text('Exportera PDF'),
                  ],
                ),
              ),
              // Placeholder for future features
              const PopupMenuItem(
                enabled: false,
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('Dela historik', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary stats with export button
          buildSummaryStats(context, allRecords),

          // Filter and sort controls
          _buildFilterAndSortControls(),

          // Records list
          Expanded(
            child: filteredRecords.isEmpty
                ? _buildEmptyState()
                : _buildRecordsList(filteredRecords),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSortControls() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Header - always visible
          InkWell(
            onTap: () {
              setState(() {
                _isFilterExpanded = !_isFilterExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Filter & Sortering',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Show active filters count
                  if (_filterType != 'all' || _sortBy != 'date_desc')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _filterType != 'all' || _sortBy != 'date_desc'
                            ? '1'
                            : '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    _isFilterExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Filter chips
                  Row(
                    children: [
                      Text(
                        'Filter:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('all', 'Alla', null),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'service',
                                'Service',
                                Icons.build,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'parts',
                                'Reservdelar',
                                Icons.settings,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'besiktning',
                                'Besiktning',
                                Icons.verified,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                'other',
                                'Annat',
                                Icons.description,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Sort dropdown
                  Row(
                    children: [
                      Text(
                        'Sortera:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButton<String>(
                            value: _sortBy,
                            isExpanded: true,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _sortBy = value;
                                });
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 'date_desc',
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16),
                                    SizedBox(width: 8),
                                    Text('Nyast först'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'date_asc',
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16),
                                    SizedBox(width: 8),
                                    Text('Äldst först'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'cost_desc',
                                child: Row(
                                  children: [
                                    Icon(Icons.trending_down, size: 16),
                                    SizedBox(width: 8),
                                    Text('Högst kostnad'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'cost_asc',
                                child: Row(
                                  children: [
                                    Icon(Icons.trending_up, size: 16),
                                    SizedBox(width: 8),
                                    Text('Lägst kostnad'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState: _isFilterExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String type, String label, IconData? icon) {
    final isSelected = _filterType == type;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 4)],
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _filterType = type;
        });
      },
    );
  }

  Widget _buildRecordsList(List<MaintenanceRecord> records) {
    // Group by year and month
    final groupedRecords = <String, List<MaintenanceRecord>>{};
    for (var record in records) {
      final key =
          '${record.date.year}-${record.date.month.toString().padLeft(2, '0')}';
      groupedRecords.putIfAbsent(key, () => []).add(record);
    }

    final sortedKeys = groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Newest first

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final monthRecords = groupedRecords[key]!;
        final date = monthRecords.first.date;
        final monthName = _getMonthName(date.month);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 8, bottom: 8),
              child: Row(
                children: [
                  Text(
                    '$monthName ${date.year}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            // Records for this month
            ...monthRecords.map(
              (record) => MaintenanceListItem(record: record),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Inga poster hittades',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _filterType == 'all'
                  ? 'Lägg till din första service'
                  : 'Prova ett annat filter',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  List<MaintenanceRecord> _getFilteredAndSortedRecords(
    List<MaintenanceRecord> records,
  ) {
    // Filter
    var filtered = records;
    if (_filterType != 'all') {
      filtered = records.where((r) => r.type == _filterType).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'date_asc':
        filtered.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'date_desc':
        filtered.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'cost_asc':
        filtered.sort((a, b) {
          final aCost = a.cost ?? double.infinity;
          final bCost = b.cost ?? double.infinity;
          return aCost.compareTo(bCost);
        });
        break;
      case 'cost_desc':
        filtered.sort((a, b) {
          final aCost = a.cost ?? 0;
          final bCost = b.cost ?? 0;
          return bCost.compareTo(aCost);
        });
        break;
    }

    return filtered;
  }

  void _exportPDF() async {
    // Get vehicle info
    final vehicle = ref
        .read(vehiclesProvider)
        .firstWhere((v) => v.id == widget.vehicleId);

    final records = ref.read(maintenanceProvider(widget.vehicleId));

    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingen servicehistorik att exportera'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show loading dialog
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
                Text('Skapar PDF...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Generate PDF
      final pdfFile = await PdfExportService.generateMaintenancePDF(
        vehicle: vehicle,
        records: records,
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Share PDF
      await PdfExportService.sharePDF(pdfFile);
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fel vid PDF-export: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Mars',
      'April',
      'Maj',
      'Juni',
      'Juli',
      'Augusti',
      'September',
      'Oktober',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
