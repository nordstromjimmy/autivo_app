import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/checklist_state.dart';
import 'models/vehicle.dart';
import 'models/maintenance_record.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(VehicleAdapter());
  Hive.registerAdapter(MaintenanceRecordAdapter());
  Hive.registerAdapter(ChecklistStateAdapter());

  await Hive.openBox<Vehicle>('vehicles');
  await Hive.openBox<MaintenanceRecord>('maintenance');
  await Hive.openBox<ChecklistState>('checklist');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Besiktningsappen',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
