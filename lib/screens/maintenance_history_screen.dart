import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/maintenance_record.dart';
import '../providers/maintenance_provider.dart';
import '../widgets/maintenance_list_item.dart';

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
            icon: const Icon(Icons.sort),
            tooltip: 'Sortera',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'date_desc',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: _sortBy == 'date_desc' ? Colors.blue : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Nyast först'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'date_asc',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 20,
                      color: _sortBy == 'date_asc' ? Colors.blue : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Äldst först'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'cost_desc',
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 20,
                      color: _sortBy == 'cost_desc' ? Colors.blue : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Högst kostnad'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'cost_asc',
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 20,
                      color: _sortBy == 'cost_asc' ? Colors.blue : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Lägst kostnad'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary stats
          _buildSummaryStats(allRecords),

          // Filter chips
          _buildFilterChips(),

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

  Widget _buildSummaryStats(List<MaintenanceRecord> records) {
    final totalCost = records
        .where((r) => r.cost != null)
        .fold<double>(0, (sum, r) => sum + r.cost!);

    final thisYearRecords = records
        .where((r) => r.date.year == DateTime.now().year)
        .toList();

    final thisYearCost = thisYearRecords
        .where((r) => r.cost != null)
        .fold<double>(0, (sum, r) => sum + r.cost!);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sammanfattning',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'Totalt',
                  '${records.length}',
                  'poster',
                  Icons.list,
                ),
                _buildStatItem(
                  context,
                  'Total kostnad',
                  '${totalCost.toStringAsFixed(0)} kr',
                  'alla tider',
                  Icons.account_balance_wallet,
                ),
                _buildStatItem(
                  context,
                  'I år',
                  '${thisYearCost.toStringAsFixed(0)} kr',
                  '${thisYearRecords.length} poster',
                  Icons.calendar_today,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    String subtitle,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('all', 'Alla', null),
          const SizedBox(width: 8),
          _buildFilterChip('service', 'Service', Icons.build),
          const SizedBox(width: 8),
          _buildFilterChip('parts', 'Reservdelar', Icons.settings),
          const SizedBox(width: 8),
          _buildFilterChip('besiktning', 'Besiktning', Icons.verified),
          const SizedBox(width: 8),
          _buildFilterChip('other', 'Annat', Icons.description),
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${monthRecords.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
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
