// Import Firebase authentication (for login/signup)
import 'package:firebase_auth/firebase_auth.dart';

// Import Flutter UI components
import 'package:flutter/material.dart';

// Import your custom authentication service
import '../services/auth_service.dart';

// Login screen widget (stateful because UI changes)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// State class that holds the logic and UI state
class _LoginScreenState extends State<LoginScreen> {

  // Controllers to read email and password text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Reference to auth service
  final _auth = AuthService.instance;

  // Whether user is signing up or signing in
  bool _isSignUp = false;

  // Shows loading spinner when authenticating
  bool _isLoading = false;

  // Holds any error message to display
  String? _errorText;

  @override
  void dispose() {
    // Clean up controllers when screen is destroyed
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handles email/password login or signup
  Future<void> _submit() async {
    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      // Get user input
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Basic validation
      if (email.isEmpty || password.isEmpty) {
        setState(() {
          _errorText = 'Please enter email and password';
          _isLoading = false;
        });
        return;
      }

      // If in signup mode → create account
      if (_isSignUp) {
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // Otherwise → sign in
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      // Stop loading after success
      if (mounted) setState(() => _isLoading = false);

    } on FirebaseAuthException catch (e) {
      // Firebase-specific errors
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = e.message ?? 'Authentication failed';
        });
      }
    } catch (e) {
      // Any other error
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  // Handles Google sign-in
  Future<void> _signInWithGoogle() async {
    setState(() {
      _errorText = null;
      _isLoading = true;
    });

    try {
      // Call Google sign-in from auth service
      await _auth.signInWithGoogle();

      if (mounted) setState(() => _isLoading = false);

    } on FirebaseAuthException catch (e) {
      // Firebase error
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = e.message ?? 'Google sign in failed';
        });
      }
    } catch (e) {
      // Other error
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        // Green gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2E7D32),
              Color(0xFF1B5E20),
            ],
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),

                // App icon
                Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.95),
                ),

                const SizedBox(height: 16),

                // App title
                Text(
                  'AIFC Finance Coach',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.98),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // White login card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      // Email input
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        enabled: !_isLoading,
                      ),

                      const SizedBox(height: 16),

                      // Password input
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        enabled: !_isLoading,
                      ),

                      // Error message (only shows if exists)
                      if (_errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorText!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFB71C1C),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Main sign in / sign up button
                      FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),

                        // Show spinner when loading
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(_isSignUp ? 'Create Account' : 'Sign In'),
                      ),

                      const SizedBox(height: 16),

                      // Toggle between sign in and sign up
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() {
                                  _isSignUp = !_isSignUp;
                                  _errorText = null;
                                }),
                        child: Text(
                          _isSignUp
                              ? 'Already have an account? Sign In'
                              : 'Create Account',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Google sign in button
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
                        label: const Text('Sign in with Google'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF2E7D32)),
                          foregroundColor: const Color(0xFF1B5E20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
