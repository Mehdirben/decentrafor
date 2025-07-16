import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/admin_login_screen.dart';
import '../screens/storage_screen.dart';

class AuthenticatedStorageScreen extends StatefulWidget {
  const AuthenticatedStorageScreen({Key? key}) : super(key: key);

  @override
  State<AuthenticatedStorageScreen> createState() => _AuthenticatedStorageScreenState();
}

class _AuthenticatedStorageScreenState extends State<AuthenticatedStorageScreen> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      final isLoggedIn = AuthService.isLoggedIn;
      
      if (isLoggedIn) {
        final isAdmin = await AuthService.isAdmin();
        setState(() {
          _isAuthenticated = true;
          _isAdmin = isAdmin;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isAuthenticated = false;
          _isAdmin = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _isAdmin = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToLogin() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminLoginScreen(),
      ),
    );
    
    if (result == true) {
      // User successfully logged in, check authentication again
      await _checkAuthentication();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Storage Management'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAuthenticated || !_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Storage Management'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 24),
                Text(
                  'Authentication Required',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You need to sign in as an administrator to access storage management features.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _navigateToLogin,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In as Admin'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // User is authenticated and is admin, show storage screen
    return const Scaffold(
      body: StorageScreen(),
    );
  }
}
