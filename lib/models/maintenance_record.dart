import 'package:hive/hive.dart';

part 'maintenance_record.g.dart';

@HiveType(typeId: 1)
class MaintenanceRecord extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String vehicleId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  int? mileage;

  @HiveField(4)
  String type; // 'service', 'parts', 'besiktning'

  @HiveField(5)
  String description;

  @HiveField(6)
  double? cost;

  @HiveField(7)
  String? location;

  @HiveField(8)
  DateTime createdAt;

  MaintenanceRecord({
    required this.id,
    required this.vehicleId,
    required this.date,
    this.mileage,
    required this.type,
    required this.description,
    this.cost,
    this.location,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
