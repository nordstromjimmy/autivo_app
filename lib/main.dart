import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'core/services/notifications/notification_service.dart';
import 'features/inspection/models/checklist_state.dart';
import 'features/receipts/models/receipt.dart';
import 'features/vehicles/models/vehicle.dart';
import 'features/maintenance/models/maintenance_record.dart';
import 'shared/providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'core/services/external/revenue_cat_service.dart';
import 'core/config/supabase_config.dart';
import 'core/utils/tracking/maintenance_deletion_tracker.dart';
import 'core/utils/ui/theme.dart';
import 'screens/splash_screen.dart';
import 'core/services/auth/user_session_tracker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Stockholm'));

  final notificationService = NotificationService();
  await notificationService.initialize();

  await dotenv.load(fileName: ".env");

  await Hive.initFlutter();

  // TEMPORARY: Clear all boxes to reset schema
  /*  
  await Hive.deleteBoxFromDisk('vehicles');
  await Hive.deleteBoxFromDisk('maintenance_records');
  await Hive.deleteBoxFromDisk('checklist'); 
  await Hive.deleteBoxFromDisk('receipts'); 
  */

  Hive.registerAdapter(VehicleAdapter());
  Hive.registerAdapter(MaintenanceRecordAdapter());
  Hive.registerAdapter(ChecklistStateAdapter());
  Hive.registerAdapter(ReceiptAdapter());

  await Hive.openBox<Vehicle>('vehicles');
  await Hive.openBox<MaintenanceRecord>('maintenance_records');
  await Hive.openBox<ChecklistState>('checklist');
  await Hive.openBox<Receipt>('receipts');

  await UserSessionTracker.initialize();
  await MaintenanceDeletionTracker.initialize();

  await SupabaseConfig.initialize();

  String revenueCatApiKey;

  if (Platform.isIOS) {
    revenueCatApiKey = 'appl_your_ios_key_here';
  } else {
    revenueCatApiKey = 'goog_rACkxKFNfcoLyHBphVvdqdTuHdz';
  }

  await RevenueCatService().initialize(revenueCatApiKey);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Autivo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: const Locale('sv', 'SE'),
      supportedLocales: const [
        Locale('sv', 'SE'),
        Locale('en', 'US'), // English (fallback)
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Routes
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
