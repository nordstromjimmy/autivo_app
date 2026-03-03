import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Provider for app version info
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

/// Convenience provider for formatted version string
final appVersionProvider = Provider<AsyncValue<String>>((ref) {
  final packageInfoAsync = ref.watch(packageInfoProvider);

  return packageInfoAsync.when(
    data: (info) => AsyncValue.data('${info.version} (${info.buildNumber})'),
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
  );
});
