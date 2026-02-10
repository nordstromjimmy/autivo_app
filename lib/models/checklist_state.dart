import 'package:hive/hive.dart';

part 'checklist_state.g.dart';

@HiveType(typeId: 4)
class ChecklistState extends HiveObject {
  @HiveField(0)
  String vehicleId;

  @HiveField(1)
  Map<String, bool> checkedItems;

  @HiveField(2)
  DateTime? lastUpdated;

  @HiveField(3)
  DateTime? lastCompleted; // When all items were checked

  ChecklistState({
    required this.vehicleId,
    required this.checkedItems,
    this.lastUpdated,
    this.lastCompleted,
  });

  // Helper to check if all items are checked
  bool get isComplete => checkedItems.values.every((checked) => checked);

  // Count of checked items
  int get checkedCount =>
      checkedItems.values.where((checked) => checked).length;

  // Total items
  int get totalItems => checkedItems.length;

  // Progress percentage
  double get progress => totalItems > 0 ? checkedCount / totalItems : 0.0;
}
