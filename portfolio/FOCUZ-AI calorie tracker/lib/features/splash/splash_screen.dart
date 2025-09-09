import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../core/assets.dart';
import '../../core/constants.dart';
import '../dashboard/dashboard_screen.dart';
import '../../services/auth_service.dart';
import '../auth/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    
    // Animation lasts 2.5 seconds
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    
    // Create progress animation that goes from 0.0 to 1.0
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
    
    // Navigate to dashboard after animation completes
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        // Check if user is signed in
        final isSignedIn = _authService.isSignedIn;
        
        // Navigate to the appropriate screen
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => isSignedIn 
              ? const DashboardScreen() 
              : const LoginScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: AppDurations.long,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Background with particles animation
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: LottieBuilder.asset(
                  AppAssets.lottieSplash,
                  fit: BoxFit.cover,
                  animate: true,
                  repeat: true,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(); // Fallback when Lottie isn't available
                  },
                ),
              ),
            ),
            
            // Main content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Centered FOCUZ logo (larger size)
                Expanded(
                  child: Center(
                    child: Hero(
                      tag: 'app_logo',
                      child: Image.asset(
                        // Use theme-appropriate logo
                        isDarkMode ? AppAssets.splashFocuzLogoDark : AppAssets.splashFocuzLogo,
                        width: screenSize.width * 0.7, // Increased size (70% of screen width)
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                
                // Company logo at the bottom with some spacing
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.s48),
                  child: Image.asset(
                    isDarkMode ? AppAssets.splashCompanyLogoDark : AppAssets.splashCompanyLogo,
                    height: 60,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
            
            // Progress bar at the bottom
            Positioned(
              bottom: AppDimensions.s24,
              left: AppDimensions.s32,
              right: AppDimensions.s32,
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Loading your health data...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 