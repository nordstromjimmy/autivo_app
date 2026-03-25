import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'purchase_provider.dart';

/// Provider to fetch premium status from Supabase users table
final supabasePremiumStatusProvider = FutureProvider<bool>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;

  try {
    final response = await Supabase.instance.client
        .from('users')
        .select('is_premium')
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) {
      // User row doesn't exist yet - create it
      await Supabase.instance.client.from('users').insert({
        'id': user.id,
        'email': user.email,
      });
      return false;
    }

    return response['is_premium'] as bool? ?? false;
  } catch (e) {
    print('Error fetching Supabase premium status: $e');
    return false;
  }
});

/// Combined premium status provider with proper loading states
/// This is what UI widgets should use to display premium status
final combinedPremiumStatusProvider = Provider<AsyncValue<bool>>((ref) {
  final user = Supabase.instance.client.auth.currentUser;

  // If no user, return false immediately
  if (user == null) {
    return const AsyncValue.data(false);
  }

  final revenueCatStatus = ref.watch(premiumStatusProvider);
  final supabaseStatus = ref.watch(supabasePremiumStatusProvider);

  // If EITHER is still loading, show loading state
  if (revenueCatStatus.isLoading || supabaseStatus.isLoading) {
    return const AsyncValue.loading();
  }

  // If EITHER has an error, propagate the error
  if (revenueCatStatus.hasError) {
    return AsyncValue.error(
      revenueCatStatus.error!,
      revenueCatStatus.stackTrace ?? StackTrace.current,
    );
  }
  if (supabaseStatus.hasError) {
    return AsyncValue.error(
      supabaseStatus.error!,
      supabaseStatus.stackTrace ?? StackTrace.current,
    );
  }

  // Both loaded successfully - combine results (OR logic)
  final hasRevenueCat = revenueCatStatus.value ?? false;
  final hasSupabase = supabaseStatus.value ?? false;
  final hasPremium = hasRevenueCat || hasSupabase;

  return AsyncValue.data(hasPremium);
});
