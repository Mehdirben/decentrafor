import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsernameService {
  static const String _usernameKey = 'forum_username';
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get stored username
  Future<String?> getStoredUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // Store username locally
  Future<void> storeUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final response = await _supabase
          .from('forum_users')
          .select('username')
          .eq('username', username.toLowerCase())
          .maybeSingle();
      
      return response == null;
    } catch (e) {
      print('Error checking username availability: $e');
      return false;
    }
  }

  // Register username in database
  Future<String?> registerUsername(String username) async {
    try {
      final response = await _supabase
          .from('forum_users')
          .insert({
            'username': username.toLowerCase(),
            'display_name': username,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      await storeUsername(username);
      return response['id'];
    } catch (e) {
      print('Error registering username: $e');
      return null;
    }
  }

  // Get user ID by username
  Future<String?> getUserId(String username) async {
    try {
      final response = await _supabase
          .from('forum_users')
          .select('id')
          .eq('username', username.toLowerCase())
          .single();

      return response['id'];
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // Clear stored username
  Future<void> clearUsername() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
  }

  // Static methods for convenience
  static Future<String?> getUsername() async {
    final service = UsernameService();
    return await service.getStoredUsername();
  }

  static Future<void> setUsername(String username) async {
    final service = UsernameService();
    await service.storeUsername(username);
  }
}
