import 'package:flutter/material.dart';
import 'package:focuz/services/auth_service.dart';
import 'package:focuz/app_theme.dart';
import 'package:lottie/lottie.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'welcome_screen.dart';
import 'email_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting Google Sign-in flow');
      final result = await _authService.signInWithGoogle();
      
      if (result != null && mounted) {
        // Successfully signed in
        print('Sign-in successful: ${result.user?.displayName}');
        
        // Navigate to welcome screen instead of home
        if (mounted) {
          print('Navigating to welcome screen after successful login');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          );
        }
      } else if (mounted) {
        // User cancelled sign-in or error occurred
        print('Sign-in was cancelled or failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-in was cancelled or failed'))
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error during sign-in: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing in: $e'))
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToEmailLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const EmailLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo or app name
                  Hero(
                    tag: 'app_logo',
                    child: Lottie.asset(
                      'assets/lottie/fitness-animation.json',
                      width: 200,
                      height: 200,
                      repeat: true,
                      animate: true,
                      errorBuilder: (context, error, stackTrace) {
                        print('Error loading Lottie animation: $error');
                        return Container(
                          width: 200,
                          height: 200,
                          color: Colors.white24,
                          child: const Center(
                            child: Icon(Icons.fitness_center, size: 80, color: AppTheme.primaryColor),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // App name and tagline
                  Text(
                    'FOCUZ',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 42,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    'Your health journey starts here',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      color: AppTheme.textColor,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Google Sign-In button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    icon: _isLoading 
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const FaIcon(
                          FontAwesomeIcons.google,
                          color: Colors.white,
                        ),
                    label: Text(
                      _isLoading ? 'Signing in...' : 'Sign in with Google',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Email/Password Sign-In button
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _navigateToEmailLogin,
                    icon: const Icon(Icons.email_outlined, color: AppTheme.primaryColor),
                    label: const Text(
                      'Sign in with Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Privacy policy text
                  Text(
                    'By signing in, you agree to our Terms of Service and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 