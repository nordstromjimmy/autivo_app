import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import '../widgets/receipt_card.dart';

class ReceiptsGalleryScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  final String vehicleName;

  const ReceiptsGalleryScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  ConsumerState<ReceiptsGalleryScreen> createState() =>
      _ReceiptsGalleryScreenState();
}

class _ReceiptsGalleryScreenState extends ConsumerState<ReceiptsGalleryScreen> {
  String _sortBy = 'date_desc'; // date_desc, date_asc, amount_desc, amount_asc
  bool _isFilterExpanded = false;

  @override
  Widget build(BuildContext context) {
    final allReceipts = ref.watch(receiptsForVehicleProvider(widget.vehicleId));
    final sortedReceipts = _getSortedReceipts(allReceipts);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kvitton'),
            Text(
              widget.vehicleName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Stats card
          _buildStatsCard(allReceipts),

          // Sort controls
          _buildSortControls(),

          // Receipts grid
          Expanded(
            child: sortedReceipts.isEmpty
                ? _buildEmptyState()
                : _buildReceiptsGrid(sortedReceipts),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(List<Receipt> receipts) {
    final totalAmount = receipts
        .where((r) => r.amount != null)
        .fold<double>(0, (sum, r) => sum + r.amount!);

    final receiptsWithAmount = receipts.where((r) => r.amount != null).length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Totalt',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${receipts.length}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    receipts.length == 1 ? 'kvitto' : 'kvitton',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 60, color: Colors.grey[300]),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Summa',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${totalAmount.toStringAsFixed(0)} kr',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$receiptsWithAmount med belopp',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortControls() {
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
                    Icons.sort,
                    size: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Sortering',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
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

                  // Sort dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
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
                          value: 'amount_desc',
                          child: Row(
                            children: [
                              Icon(Icons.trending_down, size: 16),
                              SizedBox(width: 8),
                              Text('Högst belopp'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'amount_asc',
                          child: Row(
                            children: [
                              Icon(Icons.trending_up, size: 16),
                              SizedBox(width: 8),
                              Text('Lägst belopp'),
                            ],
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildReceiptsGrid(List<Receipt> receipts) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      itemCount: receipts.length,
      itemBuilder: (context, index) {
        return ReceiptCard(receipt: receipts[index]);
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
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Inga kvitton',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Lägg till ditt första kvitto',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  List<Receipt> _getSortedReceipts(List<Receipt> receipts) {
    final sorted = List<Receipt>.from(receipts);

    switch (_sortBy) {
      case 'date_asc':
        sorted.sort((a, b) {
          final aDate = a.date ?? DateTime(1970);
          final bDate = b.date ?? DateTime(1970);
          return aDate.compareTo(bDate);
        });
        break;
      case 'date_desc':
        sorted.sort((a, b) {
          final aDate = a.date ?? DateTime(1970);
          final bDate = b.date ?? DateTime(1970);
          return bDate.compareTo(aDate);
        });
        break;
      case 'amount_asc':
        sorted.sort((a, b) {
          final aAmount = a.amount ?? double.infinity;
          final bAmount = b.amount ?? double.infinity;
          return aAmount.compareTo(bAmount);
        });
        break;
      case 'amount_desc':
        sorted.sort((a, b) {
          final aAmount = a.amount ?? 0;
          final bAmount = b.amount ?? 0;
          return bAmount.compareTo(aAmount);
        });
        break;
    }

    return sorted;
  }
}
