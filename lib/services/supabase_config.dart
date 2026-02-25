import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://fuhymnnxqxppvtbhiyca.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ1aHltbm54cXhwcHZ0YmhpeWNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEwMDI0MjcsImV4cCI6MjA4NjU3ODQyN30.rLj_5PpcH03O8HWkwdd9r7kEjI2hLGK1HnJdhM7diDM';

  static SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase (call this in main.dart)
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      // Optional: Enable debug mode during development
      // debug: true,
    );
  }

  // Check if user is signed in
  static bool get isSignedIn => client.auth.currentUser != null;

  // Get current user ID
  static String? get currentUserId => client.auth.currentUser?.id;

  // Get current user email
  static String? get currentUserEmail => client.auth.currentUser?.email;
}
