import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/supabase_config.dart';

class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Get current user
  User? get currentUser => _client.auth.currentUser;

  // Check if signed in
  bool get isSignedIn => currentUser != null;

  // Get user ID
  String? get userId => currentUser?.id;

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /*   // Anonymous to authenticated migration
  // When user signs up after using app anonymously
  Future<void> migrateAnonymousData({
    required String newUserId,
    required Function(String userId) onMigrate,
  }) async {
    // This will be called when user signs up
    // We'll update all local data to have the new userId
    await onMigrate(newUserId);
  } */
}
