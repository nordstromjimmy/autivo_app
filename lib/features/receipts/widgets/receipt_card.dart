import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/receipt.dart';
import '../providers/receipt_provider.dart';
import '../screens/receipt_detail_screen.dart';

class ReceiptCard extends ConsumerWidget {
  final Receipt receipt;
  final VoidCallback? onTap;

  const ReceiptCard({super.key, required this.receipt, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap:
            onTap ??
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ReceiptDetailScreen(receiptId: receipt.id),
                ),
              );
            },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image thumbnail - takes up fixed space
            AspectRatio(
              aspectRatio: 1.0, // Square image
              child: FutureBuilder<File?>(
                future: ref
                    .read(receiptNotifierProvider.notifier)
                    .getLocalFile(receipt),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.file(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    );
                  }

                  // Fallback
                  return Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.receipt,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Info section - flexible, takes remaining space
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize:
                      MainAxisSize.min, // Don't expand more than needed
                  children: [
                    // Description (truncated if too long)
                    if (receipt.description != null &&
                        receipt.description!.isNotEmpty)
                      Text(
                        receipt.description!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1, // Only show 1 line
                        overflow:
                            TextOverflow.ellipsis, // Show "..." when truncated
                      ),

                    // Date
                    if (receipt.date != null)
                      Text(
                        _formatDate(receipt.date!),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    // Amount
                    if (receipt.amount != null)
                      Text(
                        '${receipt.amount!.toStringAsFixed(0)} kr',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    // Sync indicator (if needed)
                    if (receipt.needsSync) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.cloud_upload,
                            size: 10,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Osynkad',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.orange[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
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
}
