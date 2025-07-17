import 'package:flutter/material.dart';
import '../services/username_service.dart';
import '../services/auth_service.dart';

class UsernameProvider with ChangeNotifier {
  final UsernameService _usernameService = UsernameService();
  
  String? _currentUsername;
  String? _currentUserId;
  bool _isLoading = false;
  bool _isAdmin = false;
  String? _error;

  // Getters
  String? get currentUsername => _currentUsername;
  String? get currentUserId => _currentUserId;
  bool get isLoading => _isLoading;
  bool get isAdmin => _isAdmin;
  String? get error => _error;
  bool get hasUsername => _currentUsername != null;

  // Initialize - check for stored username
  Future<void> initialize() async {
    _setLoading(true);
    try {
      final storedUsername = await _usernameService.getStoredUsername();
      if (storedUsername != null) {
        final userId = await _usernameService.getUserId(storedUsername);
        if (userId != null) {
          _currentUsername = storedUsername;
          _currentUserId = userId;
          
          // Check admin status
          _isAdmin = await AuthService.isAdmin();
        } else {
          // Username exists locally but not in database, clear it
          await _usernameService.clearUsername();
        }
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize username: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      return await _usernameService.isUsernameAvailable(username);
    } catch (e) {
      _error = 'Failed to check username availability: $e';
      notifyListeners();
      return false;
    }
  }

  // Set username
  Future<bool> setUsername(String username) async {
    _setLoading(true);
    try {
      // Check if username is available
      final isAvailable = await _usernameService.isUsernameAvailable(username);
      if (!isAvailable) {
        _error = 'Username is already taken';
        _setLoading(false);
        return false;
      }

      // Register username
      final userId = await _usernameService.registerUsername(username);
      if (userId != null) {
        _currentUsername = username;
        _currentUserId = userId;
        
        // Check admin status
        _isAdmin = await AuthService.isAdmin();
        
        _error = null;
        _setLoading(false);
        return true;
      } else {
        _error = 'Failed to register username';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Failed to set username: $e';
      _setLoading(false);
      return false;
    }
  }

  // Clear username
  Future<void> clearUsername() async {
    try {
      await _usernameService.clearUsername();
      _currentUsername = null;
      _currentUserId = null;
      _isAdmin = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear username: $e';
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
