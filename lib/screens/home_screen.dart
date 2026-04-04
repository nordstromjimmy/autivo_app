import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/maintenance/providers/maintenance_provider.dart';
import '../features/vehicles/providers/vehicle_provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../core/services/sync/sync_manager.dart';
import '../core/utils/helpers/custom_snackbar.dart';
import '../features/premium/utils/vehicle_limit_checker.dart';
import '../features/premium/providers/combined_premium_provider.dart';
import '../features/premium/providers/purchase_provider.dart';
import '../features/vehicles/widgets/vehicle_card.dart';
import '../features/vehicles/screens/add_vehicle_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hasAutoSynced = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _performSync(BuildContext context, WidgetRef ref) async {
    await ref
        .read(syncManagerProvider)
        .performFullSyncWithUI(context, ref, showLoadingDialog: true);
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehiclesProvider);
    final syncManager = ref.read(syncManagerProvider);

    // Watch premium loading state — same pattern as vehicle_details_screen
    final premiumStatus = ref.watch(premiumStatusProvider);
    final supabaseStatus = ref.watch(supabasePremiumStatusProvider);
    final isPremiumLoading =
        premiumStatus.isLoading || supabaseStatus.isLoading;

    ref.listen<AsyncValue<void>>(authNotifierProvider, (previous, next) {
      next.whenData((_) async {
        if (syncManager.isSignedIn && !_hasAutoSynced) {
          if (mounted) setState(() {});
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mina Fordon'),
        elevation: 0,
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final count = ref.watch(pendingSyncCountProvider);

              if (count > 0) {
                return IconButton(
                  icon: Badge(
                    label: Text('$count'),
                    child: const Icon(Icons.cloud_upload),
                  ),
                  onPressed: () => _performSync(context, ref),
                );
              }

              return const SizedBox();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: vehicles.isEmpty
            ? SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_car_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Inga fordon tillagda',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 28.0,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Tryck på + för att lägga till ditt första fordon.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Logga in för att ladda sparade fordon.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  return VehicleCard(vehicle: vehicles[index]);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        // Null disables the button while premium status is loading
        onPressed: isPremiumLoading
            ? null
            : () async {
                final canAdd =
                    await VehicleLimitChecker.checkLimitAndShowPaywall(
                      context,
                      ref,
                    );

                if (canAdd && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddVehicleScreen(),
                    ),
                  );
                }
              },
        child: isPremiumLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Icon(Icons.add),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    final syncManager = ref.read(syncManagerProvider);
    _hasAutoSynced = false;

    if (!syncManager.isSignedIn) {
      if (mounted) {
        CustomSnackBar.showInfo(context, 'Logga in för att synkronisera');
      }
      return;
    }

    await syncManager.performFullSyncWithUI(
      context,
      ref,
      showLoadingDialog: false,
    );
  }
}
