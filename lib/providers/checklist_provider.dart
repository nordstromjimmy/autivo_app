import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/checklist_state.dart';
import '../services/storage_service.dart';

// Default checklist items
const List<Map<String, String>> defaultChecklistItems = [
  {
    'title': 'Belysning',
    'description':
        'Kontrollera alla lampor (helljus, halvljus, blinkers, bromljus)',
  },
  {
    'title': 'Vindrutetorkare',
    'description': 'Kontrollera att torkarna fungerar och inte är slitna',
  },
  {
    'title': 'Däck',
    'description': 'Mönsterdjup minst 1,6 mm. Kontrollera på alla däck.',
  },
  {
    'title': 'Bromsar',
    'description': 'Kontrollera att bromsarna känns bra och inte vibrerar',
  },
  {
    'title': 'Spegel och glas',
    'description': 'Inga sprickor i vindruta, backspeglar hela och justerbara',
  },
  {
    'title': 'Utsläpp',
    'description': 'Avgassystemet ska vara helt, inga läckage eller rost',
  },
  {
    'title': 'Oljor och vätskor',
    'description': 'Kontrollera motorolja, spolarvätska, kylvätska',
  },
  {
    'title': 'Registreringsskylt',
    'description': 'Skylten ska vara hel, ren och läsbar',
  },
  {
    'title': 'Varningstriangel',
    'description': 'Ska finnas i bilen och vara hel',
  },
  {
    'title': 'Säkerhetsbälten',
    'description': 'Alla bälten ska fungera och låsa ordentligt',
  },
];

// Notifier for triggering rebuilds
class ChecklistNotifier extends StateNotifier<int> {
  ChecklistNotifier() : super(0);

  void updateItem(String vehicleId, String itemTitle, bool checked) {
    final currentState = StorageService.getChecklistState(vehicleId);

    ChecklistState newState;
    if (currentState == null) {
      // Create new state with all items unchecked
      final items = <String, bool>{};
      for (var item in defaultChecklistItems) {
        items[item['title']!] = item['title'] == itemTitle ? checked : false;
      }
      newState = ChecklistState(
        vehicleId: vehicleId,
        checkedItems: items,
        lastUpdated: DateTime.now(),
      );
    } else {
      // Create NEW state object instead of mutating
      final newCheckedItems = Map<String, bool>.from(currentState.checkedItems);
      newCheckedItems[itemTitle] = checked;

      // Check if all items are now checked
      final isComplete = newCheckedItems.values.every((v) => v);

      newState = ChecklistState(
        vehicleId: vehicleId,
        checkedItems: newCheckedItems,
        lastUpdated: DateTime.now(),
        lastCompleted: isComplete ? DateTime.now() : null,
      );
    }

    StorageService.saveChecklistState(newState);
    state++; // Trigger rebuild
  }

  void clearChecklist(String vehicleId) {
    StorageService.clearChecklistState(vehicleId);
    state++; // Trigger rebuild
  }

  void deleteChecklist(String vehicleId) {
    StorageService.deleteChecklistState(vehicleId);
    state++; // Trigger rebuild
  }
}

// Provider for the notifier
final checklistNotifierProvider = StateNotifierProvider<ChecklistNotifier, int>(
  (ref) {
    return ChecklistNotifier();
  },
);

// Provider for getting checklist state
final checklistProvider = Provider.family<ChecklistState, String>((
  ref,
  vehicleId,
) {
  ref.watch(checklistNotifierProvider); // Watch for changes

  var state = StorageService.getChecklistState(vehicleId);

  // If no state exists, create default with all unchecked
  if (state == null) {
    final items = <String, bool>{};
    for (var item in defaultChecklistItems) {
      items[item['title']!] = false;
    }
    state = ChecklistState(vehicleId: vehicleId, checkedItems: items);
  }

  return state;
});
