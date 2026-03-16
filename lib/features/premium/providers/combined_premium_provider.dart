import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'purchase_provider.dart';

/// Combined premium status provider that checks BOTH RevenueCat AND Supabase
/// This is what UI widgets should use to display premium status
final combinedPremiumStatusProvider = StreamProvider<bool>((ref) async* {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    yield false;
    return;
  }

  // Listen to both providers and emit whenever either changes
  await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
    final revenueCatStatus = ref.read(premiumStatusProvider);
    final supabaseStatus = ref.read(supabasePremiumStatusProvider);

    final hasRevenueCatPremium = revenueCatStatus.maybeWhen(
      data: (isPremium) => isPremium,
      orElse: () => false,
    );

    if (hasRevenueCatPremium) {
      yield true;
      continue;
    }

    final hasSupabasePremium = supabaseStatus.maybeWhen(
      data: (isPremium) => isPremium,
      orElse: () => false,
    );

    yield hasSupabasePremium;
  }
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
