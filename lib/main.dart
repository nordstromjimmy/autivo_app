import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
// Remove this: import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'models/vehicle.dart';
import 'models/maintenance_record.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

// Remove this:
// final FlutterLocalNotificationsPlugin notificationsPlugin =
//     FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(VehicleAdapter());
  Hive.registerAdapter(MaintenanceRecordAdapter());
  await Hive.openBox<Vehicle>('vehicles');
  await Hive.openBox<MaintenanceRecord>('maintenance');

  // Remove notification initialization

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
