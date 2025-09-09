// Welcome Screen Layout Suggestions:
//
// 1.  **Utilize `Expanded` and `Spacer` for Responsive Spacing:**
//     Instead of fixed `SizedBox` heights, consider using `Expanded` widgets
//     or `Spacer()` to distribute vertical space more dynamically. This helps
//     adapt to different screen sizes better.
//     For example, you could wrap the main content sections in `Expanded`
//     widgets with different `flex` factors or use `Spacer()` between major elements.
//
// 2.  **Consistent Padding:**
//     Wrap the main `Column` (or its content if using `Expanded`) with a
//     `Padding` widget to ensure consistent spacing from the screen edges.
//     Example: `Padding(padding: const EdgeInsets.all(AppDimensions.s24), child: Column(...))`
//
// 3.  **Group Welcome Text and User Name:**
//     The "Welcome" text and the `_userName` could be visually grouped more
//     tightly, perhaps with less vertical space between them compared to other elements.
//
// 4.  **Structure with Multiple Columns/Rows or Stack if needed:**
//     For more complex layouts, consider if a single `Column` is always the best.
//     Sometimes a `Stack` for background elements or nested `Row`s and `Column`s
//     can offer more control. (Though for this screen, a single Column is likely fine
//     with better spacing).
//
// 5.  **Consider Aspect Ratio / Screen Size Variations:**
//     Test on various screen sizes (small phones, large phones, tablets if applicable).
//     The `LayoutBuilder` widget can be useful if you need to make significant
//     layout changes based on available space, but often flexible widgets like
//     `Expanded`, `Flexible`, and `Spacer` are enough.
//
// 6.  **Lottie Animation Size:**
//     The Lottie animation is currently fixed at 200x200. Consider making its
//     size responsive, perhaps as a fraction of screen width/height, or capped
//     at a maximum size but allowed to shrink on smaller screens.
//     Example: `height: MediaQuery.of(context).size.height * 0.25`
//
// 7.  **Loading Indicator Placement:**
//     The "Loading your fitness journey..." text and its `CircularProgressIndicator`
//     are at the bottom of the animated section. This is generally fine. Ensure it remains
//     visible and doesn't get pushed off-screen on smaller devices if other elements grow.
//
// Example of using Expanded (conceptual):
// Column(
//   children: [
//     Expanded(flex: 2, child: Center(child: Hero(... Lottie ...))),
//     Expanded(flex: 3, child: AnimatedBuilder(... Welcome Text & Name ...)),
//     // Spacer(), // Or another Expanded for the bottom loading indicator
//     // Padding(padding: EdgeInsets.only(bottom: AppDimensions.s32), child: ... Loading ...),
//   ],
// )

import 'package:flutter/material.dart';
import 'package:focuz/app_theme.dart';
import 'package:focuz/services/auth_service.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  String _userName = '';
  String _fullName = '';
  String _userEmail = '';
  String _userId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Set up animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    // Get user info
    _getUserInfo();

    // Start animation
    _animationController.forward();

    // Navigate to dashboard after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  Future<void> _getUserInfo() async {
    try {
      final user = _authService.currentUser;
      if (user != null) {
        // Save user info to SharedPreferences for persistence
        final prefs = await SharedPreferences.getInstance();
        
        // Get user details
        final fullName = user.displayName ?? 'Fitness Enthusiast';
        final email = user.email ?? '';
        final uid = user.uid;
        
        // Save to SharedPreferences
        await prefs.setString('user_display_name', fullName);
        await prefs.setString('user_email', email);
        await prefs.setString('user_id', uid);
        
        if (mounted) {
          setState(() {
            _fullName = fullName;
            // Extract first name from display name
            final nameParts = fullName.split(' ');
            _userName = nameParts.isNotEmpty ? nameParts[0] : fullName;
            _userEmail = email;
            _userId = uid;
            _isLoading = false;
          });
        }
        
        print('User info saved: $_userName ($_userEmail)');
      } else {
        // Try to load from SharedPreferences if available
        final prefs = await SharedPreferences.getInstance();
        final savedName = prefs.getString('user_display_name');
        final savedEmail = prefs.getString('user_email');
        
        if (mounted) {
          setState(() {
            if (savedName != null) {
              _fullName = savedName;
              final nameParts = savedName.split(' ');
              _userName = nameParts.isNotEmpty ? nameParts[0] : savedName;
            } else {
              _userName = 'Fitness Enthusiast';
            }
            
            _userEmail = savedEmail ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error getting user info: $e');
      if (mounted) {
        setState(() {
          _userName = 'Fitness Enthusiast';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final animationSize = screenSize.height * 0.25; // Responsive animation size
    
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Top spacer
                  const Spacer(flex: 1),
                  
                  // App logo with hero animation - Responsive size
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: Hero(
                        tag: 'app_logo',
                        child: Lottie.asset(
                          'assets/lottie/fitness-animation.json',
                          height: animationSize,
                          width: animationSize,
                          repeat: true,
                          animate: true,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading Lottie animation: $error');
                            return Container(
                              height: animationSize,
                              width: animationSize,
                              color: Colors.white24,
                              child: const Center(
                                child: Icon(Icons.fitness_center, size: 80, color: Colors.white),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  // Welcome text section - Tighter grouping of welcome and name
                  Expanded(
                    flex: 4,
                    child: AnimatedBuilder(
                      animation: _fadeInAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeInAnimation.value,
                          child: child,
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Welcome text and name grouped more tightly
                          Text(
                            'Welcome',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8), // Reduced spacing between welcome and name
                          _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  _userName,
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                          
                          // More space between name and loading indicator
                          const Spacer(),
                          
                          // Loading indicator at bottom of this section
                          const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading your fitness journey...',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom spacer
                  const Spacer(flex: 1),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
} 