import 'package:shared_preferences/shared_preferences.dart';

class AdminFeaturesService {
  static const String _adminFeaturesKey = 'admin_features_enabled';

  /// Check if admin features are currently enabled
  static Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_adminFeaturesKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Enable or disable admin features
  static Future<void> setEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_adminFeaturesKey, enabled);
    } catch (e) {
      // Silently fail
    }
  }
}
