import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/checklist_state.dart';
import 'models/vehicle.dart';
import 'models/maintenance_record.dart';
import 'screens/home_screen.dart';
import 'services/revenue_cat_service.dart';
import 'services/supabase_config.dart';
import 'utils/theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Hive.initFlutter();

  // TEMPORARY: Clear all boxes to reset schema
  //await Hive.deleteBoxFromDisk('vehicles');
  //await Hive.deleteBoxFromDisk('maintenance');
  //await Hive.deleteBoxFromDisk('checklist');

  Hive.registerAdapter(VehicleAdapter());
  Hive.registerAdapter(MaintenanceRecordAdapter());
  Hive.registerAdapter(ChecklistStateAdapter());

  await Hive.openBox<Vehicle>('vehicles');
  await Hive.openBox<MaintenanceRecord>('maintenance_records');
  await Hive.openBox<ChecklistState>('checklist');

  await SupabaseConfig.initialize();

  final revenueCatApiKey = dotenv.env['REVENUE_CAT_API_KEY'];
  if (revenueCatApiKey != null) {
    await RevenueCatService().initialize(revenueCatApiKey);
  } else {
    print('⚠️ RevenueCat API key not found in .env file');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autivo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
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
