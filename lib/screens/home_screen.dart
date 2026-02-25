import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/vehicle_provider.dart';
import '../services/sync_manager.dart';
import '../widgets/vehicle_card.dart';
import 'add_vehicle_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();

    // Auto-sync on app start
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final syncManager = ref.read(syncManagerProvider);

        // Only sync if user is signed in
        if (syncManager.isSignedIn) {
          try {
            // Full sync (pull then push)
            // SyncManager automatically refreshes providers after sync
            await syncManager.fullSync();
          } catch (e) {
            // Silent fail - don't bother user if sync fails on startup
            debugPrint('Auto-sync failed: $e');
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehiclesProvider);
    final syncManager = ref.read(syncManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mina Fordon'),
        elevation: 0,
        centerTitle: true,
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final syncManager = ref.read(syncManagerProvider);
              final count = syncManager.totalPendingCount;

              if (count > 0) {
                return IconButton(
                  icon: Badge(
                    label: Text('$count'),
                    child: const Icon(Icons.cloud_upload),
                  ),
                  onPressed: () async {
                    // Show loading
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 16),
                              Text('Synkroniserar...'),
                            ],
                          ),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }

                    // Sync (SyncManager automatically refreshes providers)
                    final result = await syncManager.fullSync();

                    // Show result
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result.toString()),
                          backgroundColor: result.success
                              ? Colors.green
                              : Colors.red,
                        ),
                      );
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh(SyncManager syncManager) async {
    // Only sync if user is signed in
    if (!syncManager.isSignedIn) {
      // Show message that sync requires sign in
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logga in för att synkronisera'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      // Perform full sync
      await syncManager.fullSync();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [SizedBox(width: 12), Text('Uppdaterad')]),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Synkronisering misslyckades: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
