import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/maintenance_provider.dart';
import '../providers/vehicle_provider.dart';
import '../providers/auth_provider.dart';
import '../services/sync_manager.dart';
import '../utils/custom_snackbar.dart';
import '../utils/vehicle_limit_checker.dart';
import '../widgets/premium_badge.dart';
import '../widgets/vehicle_card.dart';
import 'add_vehicle_screen.dart';
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

    // Auto-sync on app start
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _performAutoSync();
    });
  }

  /// Perform auto-sync if user is signed in
  Future<void> _performAutoSync() async {
    if (!mounted) return;

    final syncManager = ref.read(syncManagerProvider);

    // Only sync if user is signed in
    if (syncManager.isSignedIn) {
      try {
        _hasAutoSynced = true;

        // Full sync (pull then push)
        await syncManager.fullSync();

        print('✅ Auto-sync completed');
      } catch (e) {
        // Silent fail - don't bother user if sync fails on startup
        debugPrint('Auto-sync failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehiclesProvider);
    final syncManager = ref.read(syncManagerProvider);

    // CRITICAL: Listen for auth state changes
    // When user logs in, trigger a sync
    ref.listen<AsyncValue<void>>(authNotifierProvider, (previous, next) {
      next.whenData((_) async {
        // User just logged in - sync immediately
        if (syncManager.isSignedIn && !_hasAutoSynced) {
          print('🔄 Auth changed - triggering sync...');
          await _performAutoSync();

          // Force rebuild after sync
          if (mounted) {
            setState(() {});
          }
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mina Fordon'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: const PremiumBadge()),
          ),
          Consumer(
            builder: (context, ref, _) {
              final syncManager = ref.read(syncManagerProvider);
              final count = ref.watch(pendingSyncCountProvider);

              if (count > 0) {
                return IconButton(
                  icon: Badge(
                    label: Text('$count'),
                    child: const Icon(Icons.cloud_upload),
                  ),
                  onPressed: () async {
                    // Show loading
                    if (context.mounted) {
                      CustomSnackBar.showSyncing(context, 'Synkroniserar...');
                    }

                    // Sync (SyncManager automatically refreshes providers)
                    final result = await syncManager.fullSync();

                    // Show result
                    if (context.mounted) {
                      if (result.success) {
                        CustomSnackBar.showSuccess(context, result.toString());
                      } else {
                        CustomSnackBar.showError(context, result.toString());
                      }
                    }
                  },
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
        onRefresh: () => _handleRefresh(syncManager),
        child: vehicles.isEmpty
            ? SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Make ListView scrollable even when empty (for pull-to-refresh)
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
                              Text(
                                'Tryck på + för att lägga till ditt första fordon',
                                style: TextStyle(color: Colors.grey[600]),
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
        onPressed: () async {
          // Check if user can add more vehicles
          final canAdd = await VehicleLimitChecker.checkLimitAndShowPaywall(
            context,
            ref,
          );

          if (canAdd && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh(SyncManager syncManager) async {
    // Reset auto-sync flag so we can sync again
    _hasAutoSynced = false;

    // Only sync if user is signed in
    if (!syncManager.isSignedIn) {
      // Show message that sync requires sign in
      if (mounted) {
        CustomSnackBar.showInfo(context, 'Logga in för att synkronisera');
      }
      return;
    }

    try {
      // Perform full sync
      await syncManager.fullSync();

      // Show success message
      if (mounted) {
        CustomSnackBar.showSuccess(context, 'Uppdaterad');
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        CustomSnackBar.showError(context, 'Synkronisering misslyckades: $e');
      }
    }
  }
}
