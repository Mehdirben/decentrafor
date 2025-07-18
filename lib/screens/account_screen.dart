import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/admin_features_service.dart';
import '../providers/username_provider.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _adminFeaturesEnabled = false;
  String? _currentUsername;
  User? _currentUser;
  
  // Controllers for login form
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Form keys
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _usernameFormKey = GlobalKey<FormState>();
  
  // Username availability checking
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  String? _lastCheckedUsername;
  
  // Timer for debouncing username checks
  Timer? _usernameCheckTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _loadUsername(); // Load username independently
    _checkAuthStatus(); // Check admin authentication separately
    _loadAdminFeaturesState();
    _animationController.forward();
  }

  Future<void> _loadUsername() async {
    try {
      // Get username from provider (this will handle initialization)
      final usernameProvider = Provider.of<UsernameProvider>(context, listen: false);
      if (mounted) {
        setState(() {
          _currentUsername = usernameProvider.currentUsername ?? 'User';
          _usernameController.text = usernameProvider.currentUsername ?? '';
        });
      }
    } catch (e) {
      // If loading fails, set default
      if (mounted) {
        setState(() {
          _currentUsername = 'User';
          _usernameController.text = '';
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    _usernameCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Check admin authentication separately from username
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && mounted) {
        setState(() {
          _isLoggedIn = true;
          _currentUser = user;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Error checking authentication: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAdminFeaturesState() async {
    try {
      final enabled = await AdminFeaturesService.isEnabled();
      if (mounted) {
        setState(() {
          _adminFeaturesEnabled = enabled;
        });
      }
    } catch (e) {
      // If loading fails, default to false
      if (mounted) {
        setState(() {
          _adminFeaturesEnabled = false;
        });
      }
    }
  }

  Future<void> _saveAdminFeaturesState(bool enabled) async {
    try {
      await AdminFeaturesService.setEnabled(enabled);
    } catch (e) {
      if (mounted) {
        _showError('Failed to save admin features state: $e');
      }
    }
  }

  Future<void> _signIn() async {
    if (!_loginFormKey.currentState!.validate()) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await AuthService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      await _checkAuthStatus();
      if (mounted) {
        _showSuccess('Signed in successfully!');
        
        // Clear form
        _emailController.clear();
        _passwordController.clear();
      }
    } catch (e) {
      if (mounted) {
        _showError('Sign in failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      await AuthService.signOut();
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _currentUser = null;
          // Don't clear _currentUsername - it stays independent
        });
        _showSuccess('Signed out successfully');
      }
    } catch (e) {
      if (mounted) {
        _showError('Sign out failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateUsername() async {
    if (!_usernameFormKey.currentState!.validate()) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final newUsername = _usernameController.text.trim();
      
      // Don't update if it's the same username
      if (newUsername == _currentUsername) {
        if (mounted) {
          _showSuccess('Username is already set to "$newUsername"');
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      
      // Use the provider's setUsername method which handles database registration
      final usernameProvider = Provider.of<UsernameProvider>(context, listen: false);
      final success = await usernameProvider.setUsername(newUsername);
      
      if (mounted) {
        if (success) {
          setState(() {
            _currentUsername = newUsername;
          });
          _showSuccess('Username updated successfully to "$newUsername"!');
        } else {
          // Show the error from the provider and reset the text field
          final errorMessage = usernameProvider.error ?? 'Failed to update username';
          _showError(errorMessage);
          
          // Reset the text field to the current username
          setState(() {
            _usernameController.text = _currentUsername ?? '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to update username: $e');
        // Reset the text field to the current username
        setState(() {
          _usernameController.text = _currentUsername ?? '';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.trim().isEmpty || username.trim().length < 3) {
      if (mounted) {
        setState(() {
          _isUsernameAvailable = null;
          _lastCheckedUsername = null;
          _isCheckingUsername = false;
        });
      }
      return;
    }

    final trimmedUsername = username.trim();
    
    // Don't check if it's the same as current username
    if (trimmedUsername == _currentUsername) {
      if (mounted) {
        setState(() {
          _isUsernameAvailable = true;
          _lastCheckedUsername = trimmedUsername;
          _isCheckingUsername = false;
        });
      }
      return;
    }

    // Don't check if we already checked this username
    if (trimmedUsername == _lastCheckedUsername) return;

    if (mounted) {
      setState(() {
        _isCheckingUsername = true;
        _lastCheckedUsername = trimmedUsername;
      });
    }

    try {
      final usernameProvider = Provider.of<UsernameProvider>(context, listen: false);
      final isAvailable = await usernameProvider.isUsernameAvailable(trimmedUsername);
      
      if (mounted) {
        setState(() {
          _isUsernameAvailable = isAvailable;
          _isCheckingUsername = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUsernameAvailable = null;
          _isCheckingUsername = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // Helper methods for username validation UI
  Color _getInputBorderColor() {
    final trimmedText = _usernameController.text.trim();
    
    if (trimmedText.isEmpty || trimmedText.length < 3) {
      return Colors.grey.shade300;
    }
    
    if (trimmedText == _currentUsername) {
      return const Color(0xFF8B5CF6); // Default purple for current username
    }
    
    if (_isCheckingUsername) {
      return const Color(0xFFF59E0B); // Orange while checking
    }
    
    if (_isUsernameAvailable == true) {
      return const Color(0xFF10B981); // Green for available
    }
    
    if (_isUsernameAvailable == false) {
      return const Color(0xFFEF4444); // Red for taken
    }
    
    return const Color(0xFF8B5CF6); // Default purple
  }

  Widget? _buildUsernameStatusIcon() {
    final trimmedText = _usernameController.text.trim();
    
    if (trimmedText.isEmpty || trimmedText.length < 3) {
      return null;
    }
    
    if (trimmedText == _currentUsername) {
      return const Icon(
        Icons.check_circle,
        color: Color(0xFF8B5CF6),
        size: 20,
      );
    }
    
    if (_isCheckingUsername) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
        ),
      );
    }
    
    if (_isUsernameAvailable == true) {
      return const Icon(
        Icons.check_circle,
        color: Color(0xFF10B981),
        size: 20,
      );
    }
    
    if (_isUsernameAvailable == false) {
      return const Icon(
        Icons.cancel,
        color: Color(0xFFEF4444),
        size: 20,
      );
    }
    
    return null;
  }

  String _getHelperText() {
    final trimmedText = _usernameController.text.trim();
    
    if (trimmedText.isEmpty || trimmedText.length < 3) {
      return 'This will be your display name in the forum';
    }
    
    if (trimmedText == _currentUsername) {
      return 'This is your current username';
    }
    
    if (_isCheckingUsername) {
      return 'Checking availability...';
    }
    
    if (_isUsernameAvailable == true) {
      return 'Username is available!';
    }
    
    if (_isUsernameAvailable == false) {
      return 'Username is already taken';
    }
    
    return 'This will be your display name in the forum';
  }

  Color _getHelperTextColor() {
    final trimmedText = _usernameController.text.trim();
    
    if (trimmedText.isEmpty || trimmedText.length < 3) {
      return Colors.grey.shade600;
    }
    
    if (trimmedText == _currentUsername) {
      return const Color(0xFF8B5CF6);
    }
    
    if (_isCheckingUsername) {
      return const Color(0xFFF59E0B);
    }
    
    if (_isUsernameAvailable == true) {
      return const Color(0xFF10B981);
    }
    
    if (_isUsernameAvailable == false) {
      return const Color(0xFFEF4444);
    }
    
    return Colors.grey.shade600;
  }

  bool _canUpdateUsername() {
    final trimmedText = _usernameController.text.trim();
    
    // Can't update if empty or too short
    if (trimmedText.isEmpty || trimmedText.length < 3) {
      return false;
    }
    
    // Can update if it's the current username (no change needed, but not an error)
    if (trimmedText == _currentUsername) {
      return true;
    }
    
    // Can't update if still checking or username is taken
    if (_isCheckingUsername || _isUsernameAvailable == false) {
      return false;
    }
    
    // Can update if username is available or hasn't been checked yet
    return _isUsernameAvailable == true || _isUsernameAvailable == null;
  }

  String _getUpdateButtonText() {
    final trimmedText = _usernameController.text.trim();
    
    if (trimmedText == _currentUsername) {
      return 'Username Already Set';
    }
    
    if (_currentUsername != null) {
      return 'Update Username';
    }
    
    return 'Set Username';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _isLoading
            ? _buildLoadingState()
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    // Username section - always available for all users
                    _buildUsernameSection(),
                    const SizedBox(height: 32),
                    // Admin login section
                    _buildAdminLoginSection(),
                    if (_isLoggedIn) ...[
                      const SizedBox(height: 32),
                      _buildAdminFeaturesToggle(),
                      const SizedBox(height: 32),
                      _buildSignOutSection(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Loading account information...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_circle_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set your username and manage admin access',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminFeaturesToggle() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _adminFeaturesEnabled 
              ? const Color(0xFF10B981).withValues(alpha: 0.3)
              : const Color(0xFFEF4444).withValues(alpha: 0.3)
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _adminFeaturesEnabled 
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _adminFeaturesEnabled ? Icons.admin_panel_settings : Icons.security,
                  color: _adminFeaturesEnabled 
                      ? const Color(0xFF10B981) 
                      : const Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Features',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      _adminFeaturesEnabled 
                          ? 'Admin features are currently enabled'
                          : 'Admin features are currently disabled',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _adminFeaturesEnabled,
                onChanged: (value) async {
                  if (mounted) {
                    setState(() {
                      _adminFeaturesEnabled = value;
                    });
                  }
                  await _saveAdminFeaturesState(value);
                  if (mounted) {
                    _showSuccess(
                      _adminFeaturesEnabled 
                          ? 'Admin features enabled' 
                          : 'Admin features disabled'
                    );
                  }
                },
                activeColor: const Color(0xFF10B981),
                inactiveThumbColor: const Color(0xFFEF4444),
                inactiveTrackColor: const Color(0xFFEF4444).withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _adminFeaturesEnabled 
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _adminFeaturesEnabled 
                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.2)
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _adminFeaturesEnabled ? Icons.check_circle : Icons.info,
                      color: _adminFeaturesEnabled 
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _adminFeaturesEnabled ? 'Admin Features Active' : 'Admin Features Disabled',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _adminFeaturesEnabled 
                            ? const Color(0xFF065F46)
                            : const Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _adminFeaturesEnabled 
                      ? 'You can now delete PDFs, manage categories, and access all administrative functions.'
                      : 'Admin features are disabled. Toggle to enable PDF deletion, category management, and other admin functions.',
                  style: TextStyle(
                    fontSize: 13,
                    color: _adminFeaturesEnabled 
                        ? const Color(0xFF047857)
                        : const Color(0xFFA16207),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Admin features include:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeatureItem('Delete PDFs from the library'),
                    _buildFeatureItem('Manage PDF categories'),
                    _buildFeatureItem('Access storage management'),
                    _buildFeatureItem('View admin dashboard'),
                    _buildFeatureItem('Moderate forum content'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            Icons.fiber_manual_record,
            size: 6,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _usernameFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Username',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        'Set your display name for the forum',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _usernameController,
              onChanged: (value) {
                // Cancel previous timer
                _usernameCheckTimer?.cancel();
                
                // Start new timer for debounced checking
                _usernameCheckTimer = Timer(const Duration(milliseconds: 500), () {
                  if (mounted && _usernameController.text == value) {
                    _checkUsernameAvailability(value);
                  }
                });
              },
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: _currentUsername ?? 'Enter your username',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _getInputBorderColor(),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _getInputBorderColor(),
                  ),
                ),
                prefixIcon: const Icon(Icons.person_outline),
                suffixIcon: _buildUsernameStatusIcon(),
                helperText: _getHelperText(),
                helperStyle: TextStyle(
                  color: _getHelperTextColor(),
                  fontSize: 12,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username is required';
                }
                if (value.trim().length < 3) {
                  return 'Username must be at least 3 characters';
                }
                if (_isUsernameAvailable == false && value.trim() != _currentUsername) {
                  return 'Username is already taken';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || !_canUpdateUsername() ? null : _updateUsername,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _getUpdateButtonText(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.logout,
                  color: Color(0xFFEF4444),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You will be signed out of your account and returned to the login screen.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminLoginSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: _isLoggedIn 
            ? Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3))
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isLoggedIn 
                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                        : const Color(0xFF667EEA).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isLoggedIn ? Icons.admin_panel_settings : Icons.security,
                    color: _isLoggedIn ? const Color(0xFF10B981) : const Color(0xFF667EEA),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLoggedIn ? 'Admin Access' : 'Admin Login',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        _isLoggedIn 
                            ? 'You are signed in as an admin'
                            : 'Sign in for administrative features',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!_isLoggedIn) ...[
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Admin Email',
                  hintText: 'Enter your admin email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF667EEA)),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Admin Password',
                  hintText: 'Enter your admin password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF667EEA)),
                  ),
                  prefixIcon: const Icon(Icons.lock_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Sign In as Admin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Admin Access Active',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF065F46),
                            ),
                          ),
                          Text(
                            'Signed in as: ${_currentUser?.email}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
