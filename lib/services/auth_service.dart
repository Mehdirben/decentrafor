import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Check if user is logged in
  static bool get isLoggedIn => _client.auth.currentUser != null;

  // Get current user
  static User? get currentUser => _client.auth.currentUser;

  // Sign in with email and password
  static Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign in with email and password (alias for consistency)
  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    return signIn(email, password);
  }

  // Sign up with email and password
  static Future<AuthResponse> signUpWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Check if current user is admin
  static Future<bool> isAdmin() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      // First check if user has admin role in user metadata
      final metadata = user.userMetadata;
      if (metadata != null && metadata['role'] == 'admin') {
        return true;
      }

      // Check against the admin_users table in the database
      try {
        final response = await _client
            .from('admin_users')
            .select('id')
            .eq('email', user.email!)
            .eq('role', 'admin');
        
        return response.isNotEmpty;
      } catch (e) {
        // If database check fails, fall back to hardcoded admin emails
        const adminEmails = [
          // Add more admin emails as needed
        ];
        
        return adminEmails.contains(user.email);
      }
    } catch (e) {
      return false;
    }
  }

  // Listen to auth state changes
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
