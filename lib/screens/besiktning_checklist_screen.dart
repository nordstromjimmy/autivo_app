import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle.dart';
import '../widgets/checklist_item.dart';
import '../providers/checklist_provider.dart';

class BesiktningChecklistScreen extends ConsumerWidget {
  final Vehicle vehicle;

  const BesiktningChecklistScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklistState = ref.watch(checklistProvider(vehicle.id));
    final progress = checklistState.progress;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Besiktnings-checklista'),
        actions: [
          // Clear button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rensa alla',
            onPressed: checklistState.checkedCount > 0
                ? () => _showClearConfirmation(context, ref)
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress card
          _buildProgressCard(context, checklistState, progress),

          // Checklist items
          Expanded(
            child: SafeArea(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: defaultChecklistItems.length,
                itemBuilder: (context, index) {
                  final item = defaultChecklistItems[index];
                  final title = item['title']!;
                  return ChecklistItem(
                    title: title,
                    description: item['description']!,
                    isChecked: checklistState.checkedItems[title] ?? false,
                    onChanged: (value) {
                      ref
                          .read(checklistNotifierProvider.notifier)
                          .updateItem(vehicle.id, title, value ?? false);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    dynamic checklistState,
    double progress,
  ) {
    final isComplete = progress == 1.0;

    return Card(
      margin: const EdgeInsets.all(16),
      color: isComplete
          ? Colors.green.withValues(alpha: 0.9)
          : Theme.of(context).primaryColor.withValues(alpha: 0.7),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isComplete ? 'Klart!' : 'Framsteg',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isComplete ? Colors.white : null,
                  ),
                ),
                Text(
                  '${checklistState.checkedCount}/${checklistState.totalItems}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isComplete ? Colors.white : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isComplete
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? Colors.white : Theme.of(context).primaryColor,
                ),
                minHeight: 8,
              ),
            ),
            if (isComplete) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alla punkter kontrollerade! Din bil är redo för besiktning.',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showClearConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rensa checklista?'),
        content: const Text(
          'Detta kommer ta bort alla dina checkmarkeringar. Vill du fortsätta?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Rensa'),
          ),
        ],
      ),
    );

    // Handle the confirmation OUTSIDE the dialog context
    if (confirmed == true && context.mounted) {
      ref.read(checklistNotifierProvider.notifier).clearChecklist(vehicle.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checklista rensad'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
