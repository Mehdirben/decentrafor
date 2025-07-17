import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/username_provider.dart';

class UsernameSetupScreen extends StatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  State<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  bool _isChecking = false;
  bool _isUsernameAvailable = false;
  String? _availabilityMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _checkAvailability(String username) async {
    if (username.length < 3) {
      setState(() {
        _isUsernameAvailable = false;
        _availabilityMessage = null;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _availabilityMessage = null;
    });

    final isAvailable = await context.read<UsernameProvider>().isUsernameAvailable(username);
    
    setState(() {
      _isChecking = false;
      _isUsernameAvailable = isAvailable;
      _availabilityMessage = isAvailable 
          ? '✓ Username is available!' 
          : '✗ Username is already taken';
    });
  }

  Future<void> _setUsername() async {
    if (!_formKey.currentState!.validate() || !_isUsernameAvailable) return;

    final success = await context.read<UsernameProvider>().setUsername(_usernameController.text.trim());
    
    if (success && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      final error = context.read<UsernameProvider>().error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to set username'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a username';
    }
    if (value.trim().length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.trim().length > 20) {
      return 'Username must be less than 20 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
      return 'Username can only contain letters, numbers, and underscores';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_circle,
                          size: 80,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Choose Your Username',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Enter a unique username to participate in forum discussions. This will be your identity in the community.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            hintText: 'Enter your username',
                            prefixIcon: const Icon(Icons.person),
                            suffixIcon: _isChecking
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : _availabilityMessage != null
                                    ? Icon(
                                        _isUsernameAvailable ? Icons.check_circle : Icons.cancel,
                                        color: _isUsernameAvailable ? Colors.green : Colors.red,
                                      )
                                    : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surface,
                          ),
                          validator: _validateUsername,
                          onChanged: (value) {
                            if (_validateUsername(value) == null) {
                              _checkAvailability(value.trim());
                            } else {
                              setState(() {
                                _isUsernameAvailable = false;
                                _availabilityMessage = null;
                              });
                            }
                          },
                        ),
                        if (_availabilityMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _availabilityMessage!,
                            style: TextStyle(
                              color: _isUsernameAvailable ? Colors.green : Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        Consumer<UsernameProvider>(
                          builder: (context, usernameProvider, child) {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (usernameProvider.isLoading || !_isUsernameAvailable) 
                                    ? null 
                                    : _setUsername,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: usernameProvider.isLoading
                                    ? const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                          SizedBox(width: 12),
                                          Text('Setting Username...'),
                                        ],
                                      )
                                    : const Text('Continue to Forum'),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info, color: Colors.blue[700], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Username Guidelines',
                                    style: TextStyle(
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• 3-20 characters long\n'
                                '• Letters, numbers, and underscores only\n'
                                '• Must be unique across the platform\n'
                                '• Cannot be changed later',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
