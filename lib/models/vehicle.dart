import 'package:hive/hive.dart';

part 'vehicle.g.dart';

@HiveType(typeId: 0)
class Vehicle extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String registrationNumber;

  @HiveField(2)
  String make;

  @HiveField(3)
  String model;

  @HiveField(4)
  int year;

  @HiveField(5)
  String? fuelType;

  @HiveField(6)
  String? engineSize;

  @HiveField(7)
  DateTime nextBesiktningDate;

  @HiveField(8)
  DateTime createdAt;

  Vehicle({
    required this.id,
    required this.registrationNumber,
    required this.make,
    required this.model,
    required this.year,
    this.fuelType,
    this.engineSize,
    required this.nextBesiktningDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Helper methods
  int get daysUntilBesiktning {
    return nextBesiktningDate.difference(DateTime.now()).inDays;
  }

  bool get isBesiktningUrgent => daysUntilBesiktning <= 30;
  bool get isBesiktningOverdue => daysUntilBesiktning < 0;

  String get urgencyLevel {
    if (isBesiktningOverdue) return 'overdue';
    if (daysUntilBesiktning <= 14) return 'critical';
    if (daysUntilBesiktning <= 30) return 'warning';
    return 'ok';
  }
}
