import 'package:flutter/material.dart';
import 'package:focuz/app_theme.dart';
import 'package:focuz/services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:focuz/features/auth/screens/verify_phone_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSuccess = false;
    });

    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());
      
      // Navigate to phone verification for 2FA
      if (mounted) {
        final emailAddress = _emailController.text.trim();
        
        // Show success state temporarily
        setState(() {
          _isSuccess = true;
          _isLoading = false;
        });
        
        // Delay to show success message briefly
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => VerifyPhoneScreen(
                email: emailAddress,
              ),
            ),
          );
          
          // If phone verification was successful, keep success state
          // Otherwise reset to form view
          if (mounted) {
            setState(() {
              _isSuccess = result == true;
              if (!_isSuccess) {
                _errorMessage = 'Phone verification is required to reset your password';
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error sending password reset email: $e');
      
      // Handle specific Firebase auth errors
      String errorMessage = 'An error occurred while sending reset email';
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'No user found with this email';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email format';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Too many attempts. Please try again later';
      }
      
      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
          _isSuccess = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Reset password icon
                if (!_isSuccess) 
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        size: 50,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )
                else
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 50,
                        color: Colors.green,
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Title
                Text(
                  _isSuccess ? 'Verification Complete!' : 'Forgot Password',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _isSuccess ? Colors.green : AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  _isSuccess 
                      ? 'Password reset link has been sent to your email and your phone number has been verified. Check your email to complete the process.'
                      : 'Enter your email address and we\'ll send you a link to reset your password. For security, the reset process requires verification.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Error message
                if (_errorMessage != null && !_isSuccess)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                if (_errorMessage != null && !_isSuccess) const SizedBox(height: 24),
                
                // Email field - only show if not success
                if (!_isSuccess)
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Enter your email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryColor),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      // Simple email validation
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                
                const SizedBox(height: 24),
                
                // Send reset email button or Back to login button
                ElevatedButton(
                  onPressed: _isLoading 
                      ? null 
                      : _isSuccess 
                          ? () => Navigator.pop(context) 
                          : _sendPasswordResetEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSuccess ? Colors.green : AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isSuccess ? 'Back to Login' : 'Reset Password',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                
                if (!_isSuccess) const SizedBox(height: 16),
                
                // Back to login button
                if (!_isSuccess)
                  TextButton.icon(
                    onPressed: _isLoading ? null : () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Login'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                    ),
                  ),
                
                const Spacer(),
                
                // Security note
                if (!_isSuccess)
                  Text(
                    'For security reasons, password reset requires email verification and phone verification as a second factor.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 