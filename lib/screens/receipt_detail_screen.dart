import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/receipt_provider.dart';
import 'add_receipt_screen.dart';

class ReceiptDetailScreen extends ConsumerWidget {
  final String receiptId;

  const ReceiptDetailScreen({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = ref.watch(receiptByIdProvider(receiptId));

    if (receipt == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Kvitto')),
        body: const Center(child: Text('Kvitto hittades inte')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kvitto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddReceiptScreen(
                    vehicleId: receipt.vehicleId,
                    existingReceipt: receipt,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Full-size image
          Expanded(
            child: Container(
              color: Colors.black,
              child: FutureBuilder<File?>(
                future: ref
                    .read(receiptNotifierProvider.notifier)
                    .getLocalFile(receipt),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (snapshot.hasData && snapshot.data != null) {
                    return InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(
                        child: Image.file(snapshot.data!, fit: BoxFit.contain),
                      ),
                    );
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Kunde inte ladda bild',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Receipt info
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Description
                    if (receipt.description != null &&
                        receipt.description!.isNotEmpty)
                      Text(
                        receipt.description!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Details row
                    Row(
                      children: [
                        // Date
                        if (receipt.date != null) ...[
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(receipt.date!),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],

                        // Amount
                        if (receipt.amount != null) ...[
                          if (receipt.date != null) ...[
                            const SizedBox(width: 20),
                            Text(
                              '•',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                            const SizedBox(width: 20),
                          ],
                          Icon(
                            Icons.payments,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${receipt.amount!.toStringAsFixed(0)} kr',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Sync status
                    if (receipt.needsSync) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_upload,
                              size: 14,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Väntar på synkronisering',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'januari',
      'februari',
      'mars',
      'april',
      'maj',
      'juni',
      'juli',
      'augusti',
      'september',
      'oktober',
      'november',
      'december',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
