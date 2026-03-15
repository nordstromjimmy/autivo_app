import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/vehicles/models/vehicle.dart';
import '../../../features/receipts/providers/receipt_provider.dart';
import '../../../features/receipts/widgets/receipt_card.dart';
import '../../../features/receipts/screens/add_receipt_screen.dart';
import '../../../features/receipts/screens/receipts_gallery_screen.dart';

class VehicleReceiptsTab extends ConsumerWidget {
  final Vehicle vehicle;

  const VehicleReceiptsTab({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipts = ref.watch(receiptsForVehicleProvider(vehicle.id));

    return Column(
      children: [
        // Receipts gallery
        Expanded(
          child: receipts.isEmpty
              ? _buildEmptyState(context)
              : _buildReceiptsGrid(context, receipts, ref),
        ),

        // Add receipt button at bottom
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddReceiptScreen(vehicleId: vehicle.id),
                  ),
                );
              },
              label: const Text('Lägg till'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Inga kvitton än',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Spara kvitton för service och reparationer här',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptsGrid(
    BuildContext context,
    List<dynamic> receipts,
    WidgetRef ref,
  ) {
    // Show only last 6 receipts in grid
    final displayReceipts = receipts.take(6).toList();
    final hasMore = receipts.length > 6;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Senaste',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${receipts.length} ${receipts.length == 1 ? 'kvitto' : 'kvitton'}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Grid of receipts (2 columns)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          itemCount: displayReceipts.length,
          itemBuilder: (context, index) {
            return ReceiptCard(receipt: displayReceipts[index]);
          },
        ),

        // "View all" button if more receipts exist
        if (hasMore) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReceiptsGalleryScreen(
                    vehicleId: vehicle.id,
                    vehicleName: '${vehicle.make} ${vehicle.model}',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.grid_view),
            label: const Text('Visa alla'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ],
    );
  }
}
