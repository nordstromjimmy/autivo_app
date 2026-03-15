import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'purchase_provider.dart';

/// Combined premium status provider that checks BOTH RevenueCat AND Supabase
/// This is what UI widgets should use to display premium status
final combinedPremiumStatusProvider = FutureProvider<bool>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;
  // Check RevenueCat
  final revenueCatStatus = ref.watch(premiumStatusProvider);
  final hasRevenueCatPremium = revenueCatStatus.maybeWhen(
    data: (isPremium) => isPremium,
    orElse: () => false,
  );

  // If RevenueCat has premium, return true immediately
  if (hasRevenueCatPremium) return true;

  // Otherwise, check Supabase
  final supabaseStatus = ref.watch(supabasePremiumStatusProvider);
  return supabaseStatus.maybeWhen(
    data: (isPremium) => isPremium,
    orElse: () => false,
  );
});

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
