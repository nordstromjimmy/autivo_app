import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/sync/sync_manager.dart';
import '../../premium/providers/combined_premium_provider.dart';
import '../../premium/providers/purchase_provider.dart';

// Provider for auth service
final authServiceProvider = Provider((ref) => AuthService());

// Provider for current auth state
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.read(authServiceProvider);
  return authService.authStateChanges;
});

// Provider for current user (or null if not signed in)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Provider to check if user is signed in
final isSignedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

// Auth notifier for sign in/up/out actions
final authNotifierProvider = NotifierProvider<AuthNotifier, AsyncValue<void>>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AsyncValue<void>> {
  late final AuthService _authService;
  //late final SyncManager _syncManager;

  @override
  AsyncValue<void> build() {
    _authService = ref.read(authServiceProvider);
    // _syncManager = ref.read(syncManagerProvider);
    return const AsyncValue.data(null);
  }

  /// Sign up with email and password
  Future<void> signUp({required String email, required String password}) async {
    state = const AsyncValue.loading();

    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Migration and sync handled by _handlePostSignup in sign_up_screen.dart
        _refreshPremiumStatus();
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error(
          'Registrering misslyckades',
          StackTrace.current,
        );
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Sign in with email and password
  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();

    try {
      final response = await _authService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Sync is handled by _handlePostLogin in sign_in_screen.dart
        // Do NOT pull here — it would overwrite pending local changes
        _refreshPremiumStatus();
        state = const AsyncValue.data(null);
      } else {
        state = AsyncValue.error('Inloggning misslyckades', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();

    try {
      await _authService.signOut();

      // Clear premium status cache after logout
      _refreshPremiumStatus();

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();

    try {
      await _authService.resetPassword(email);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Refresh premium status providers
  void _refreshPremiumStatus() {
    // Invalidate all premium-related providers
    ref.invalidate(supabasePremiumStatusProvider);
    ref.invalidate(premiumStatusProvider);
    // combinedPremiumStatusProvider will auto-refresh since it depends on the above
  }
}
