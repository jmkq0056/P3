import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'app_theme.dart';
import 'features/meals/meal_provider.dart';
import 'features/water_can/water_can_provider.dart';
import 'features/weight/weight_provider.dart';
import 'features/sleep/sleep_provider.dart';
import 'features/training/training_provider.dart';
import 'services/firestore_service.dart';

/// Migration state provider to track the migration progress
class MigrationStateProvider extends ChangeNotifier {
  bool _isMigrating = false;
  String _message = '';
  
  // Constructor
  MigrationStateProvider() {
    _checkMigrationStatus();
  }
  
  bool get isMigrating => _isMigrating;
  String get message => _message;
  
  // Check if migration is in progress
  Future<void> _checkMigrationStatus() async {
    final firestoreService = FirestoreService();
    if (firestoreService.isMigrating) {
      _isMigrating = true;
      _message = 'Migrating data to Firestore...';
      notifyListeners();
      
      // Poll every 500ms until migration is completed
      while (firestoreService.isMigrating) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Migration completed
      _message = 'Migration completed!';
      notifyListeners();
      
      // Hide the message after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      _isMigrating = false;
      notifyListeners();
    }
  }
  
  // Set migration status
  void setMigrationStatus({required bool isMigrating, String? message}) {
    _isMigrating = isMigrating;
    if (message != null) _message = message;
    notifyListeners();
  }
}

/// Enhanced theme provider with SharedPreferences persistence
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;

  ThemeProvider() {
    _initializeTheme();
  }

  // Initialize theme from SharedPreferences
  Future<void> _initializeTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeIndex = prefs.getInt(_themeKey);
      
      if (savedThemeIndex != null) {
        _themeMode = ThemeMode.values[savedThemeIndex];
      } else {
        // First time user - default to system theme
        _themeMode = ThemeMode.system;
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading theme preference: $e');
      _themeMode = ThemeMode.system;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Save theme preference to SharedPreferences
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, _themeMode.index);
    } catch (e) {
      print('Error saving theme preference: $e');
    }
  }

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  
  // Get the effective brightness based on the context
  Brightness getEffectiveBrightness(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness;
    }
    return _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;
  }

  // Toggle between light and dark mode (regardless of system)
  void toggleTheme() {
    if (_themeMode == ThemeMode.system) {
      // If in system mode, switch to explicit mode based on current system brightness
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _themeMode = brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    } else {
      // Toggle between light and dark
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    }
    _saveThemePreference();
    notifyListeners();
  }

  // Set specific theme mode
  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _saveThemePreference();
      notifyListeners();
    }
  }

  // Set to follow system theme
  void useSystemTheme() {
    setThemeMode(ThemeMode.system);
  }
  
  // Get the current theme mode name for display
  String get themeModeText {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  // Get the current effective theme name for display
  String getEffectiveThemeName(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      final brightness = MediaQuery.of(context).platformBrightness;
      return brightness == Brightness.dark ? 'Dark (System)' : 'Light (System)';
    }
    return themeModeText;
  }
}

/// Main app class
class FocuzApp extends StatelessWidget {
  const FocuzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: provider.MultiProvider(
        providers: [
          provider.ChangeNotifierProvider(create: (_) => ThemeProvider()),
          provider.ChangeNotifierProvider(create: (_) => MigrationStateProvider()),
        ],
        child: provider.Consumer2<ThemeProvider, MigrationStateProvider>(
          builder: (context, themeProvider, migrationProvider, _) {
            return Builder(
              builder: (context) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  title: 'FOCUZ',
                  theme: AppTheme.lightTheme(),
                  darkTheme: AppTheme.darkTheme(),
                  themeMode: themeProvider.themeMode,
                  home: Stack(
                    children: [
                      _buildProviderTree(),
                      // Show migration overlay when migrating
                      if (migrationProvider.isMigrating)
                        _buildMigrationOverlay(context, migrationProvider.message),
                    ],
                  ),
                  routes: {
                    '/login': (context) => const LoginScreen(),
                    '/welcome': (context) => const WelcomeScreen(),
                    '/home': (context) => const DashboardScreen(),
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
  
  /// Build the provider tree
  Widget _buildProviderTree() {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (_) => MealProvider()),
        provider.Provider(create: (_) => WaterCanProvider(child: Container())),
        provider.Provider(create: (_) => WeightProvider(child: Container())),
        provider.Provider(create: (_) => SleepProvider(child: Container())),
        provider.Provider(create: (_) => TrainingProvider(child: Container())),
      ],
      child: const SplashScreen(),
    );
  }
  
  /// Build migration overlay
  Widget _buildMigrationOverlay(BuildContext context, String message) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Please wait while your data is being migrated to the cloud...',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
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