// TODO: Refactor Dashboard Structure & Implement New Features (Based on futureworks.md)
//
// GOAL:
// Transform the dashboard into a more dynamic, visually appealing, and feature-rich hub,
// aligning with the "Energetic Bloom" design palette and integrating new tracking capabilities.
// The dashboard should provide an at-a-glance overview of key metrics, progress,
// and quick access to new features like habit tracking and medication reminders.
//
// DESIGN PRINCIPLES (from futureworks.md - Phase 1):
// 1.  COLOR PALETTE ("Energetic Bloom"):
//     -   Primary: #6D28D9 (Deep Violet/Grape) - Used for primary actions, active states, highlights.
//     -   Accent 1: #F87171 (Coral Red) - Used for warnings, important callouts, secondary actions.
//     -   Accent 2: #34D399 (Mint Green) - Used for positive feedback, success states, tertiary actions.
//     -   Backgrounds:
//         -   Light Mode: #F3F4F6 (Light Gray) for overall background, #FFFFFF (White) for cards/elevated surfaces.
//         -   Dark Mode: A corresponding dark theme should be developed.
//             -   Background: A dark gray, e.g., #121212 or #1F2937 (Dark Charcoal from text color).
//             -   Cards/Surfaces: Slightly lighter dark gray, e.g., #1E1E1E or #2C3A47.
//             -   Text: Light grays/White for readability.
//     -   Text: #1F2937 (Dark Charcoal) for light mode. Inverse for dark mode.
// 2.  FONT PAIRING:
//     -   Headings: Montserrat (Bold, Semi-Bold).
//     -   Body Text: Inter (Regular, Medium).
// 3.  INSTANTANEOUS STATE UPDATES: Continue leveraging AppState and AppDateManager,
//     and consider Riverpod/Provider for more complex state interactions if needed.
//
// PROPOSED DASHBOARD SECTIONS & ENHANCEMENTS:
//
// I.  TOP SECTION: DYNAMIC GREETING & DATE/HISTORY NAVIGATION
//     -   Current: AppBar with 'Dashboard' title, refresh/calendar icon.
//     -   Enhancement:
//         -   Consider a more personalized greeting (e.g., "Good Morning, [User Name]!").
//         -   Retain easy access to date selection (current calendar icon is good).
//         -   History Mode Indicator: Ensure it's clear and visually distinct.
//             The current amber-colored bar is effective; ensure it adapts well to both light/dark themes.
//
// II. ENERGY BALANCE CARD (Already Exists)
//     -   Current: Card displaying Food, BMR, Walking, Training, Deficit/Surplus.
//     -   Enhancement:
//         -   Visuals: Apply "Energetic Bloom" palette. For instance, deficit (positive) could use Mint Green accents,
//           surplus (needs attention) could use Coral Red accents. Primary Violet for card elements.
//         -   Clarity: Ensure icons and text are crisp. The existing FontAwesomeIcons are good.
//         -   Interactivity: Retain tap to view history.
//
// III. "KEY METRICS" / "TODAY'S FOCUS" SECTION (Replaces "Today's Progress")
//      -   Current: GridView of MetricCards (Steps, Calories, Water, Sleep, Weight, Training).
//      -   Enhancement:
//          1.  VISUAL REFRESH:
//              -   MetricCards: Redesign to be more modern. Use "Energetic Bloom" colors.
//                  -   Light Mode: White cards (#FFFFFF) on Light Gray background (#F3F4F6).
//                  -   Dark Mode: Darker cards (e.g., #1E1E1E) on a very dark background (e.g., #121212).
//                  -   Use primary color (#6D28D9) or accent colors for progress indicators and icons,
//                    ensuring contrast for accessibility in both modes.
//              -   Icons: Continue using custom AppAssets icons; ensure they are clear and themed.
//              -   Progress Indicators: Enhance animations or explore new styles (e.g., slim progress bars below metric value).
//          2.  NEW METRIC WIDGETS (Integrate from Phase 2 of futureworks.md):
//              -   HABIT TRACKING SUMMARY:
//                  -   Display a summary of 1-2 key habits (e.g., "Meditation: 3/5 days completed").
//                  -   Could be a compact card or integrated into the grid.
//                  -   On tap: Navigate to Habit Tracking Screen.
//                  -   Visuals: Use accent colors for progress.
//              -   MEDICATION/SUPPLEMENT REMINDER SNAPSHOT:
//                  -   Show upcoming medication/supplement or a status (e.g., "All taken for today").
//                  -   Compact display, potentially with a small icon.
//                  -   On tap: Navigate to Medication Reminder Screen.
//          3.  CUSTOMIZABLE GRID (Future Aspiration): Allow users to choose which metrics are most important to them.
//
// IV. "QUICK ACTIONS" SECTION (Already Exists)
//     -   Current: Buttons for Add Water, Log Meal, Add Workout.
//     -   Enhancement:
//         1.  VISUALS:
//             -   Buttons: Style with "Energetic Bloom" palette. Use primary color for key actions.
//             -   Icons: Ensure consistency and clarity.
//         2.  NEW QUICK ACTIONS (from Phase 2 & 3 of futureworks.md):
//             -   "Log Habit": Quick shortcut to log progress for a predefined habit.
//             -   "Add Reminder": Shortcut to Medication/Supplement reminder setup.
//             -   "Voice Command": The existing FAB is good, ensure it's visually integrated.
//         3.  CONTEXTUAL ACTIONS: If in "History Mode," ensure actions clearly state they are for the selected past date.
//             (Already partially implemented with "(Past)" in labels).
//
// V.  AI & ADVANCED FEATURES INTEGRATION (Phase 3)
//     -   While full screens for AI Chatbot and Meal Analysis are separate, the dashboard could have:
//         1.  AI CHATBOT QUICK ACCESS:
//             -   A small, non-intrusive button or entry point to the AI Diet Chatbot.
//             -   Could be in "Quick Actions" or a floating element if design allows.
//         2.  MEAL ANALYSIS PROMPT (Contextual):
//             -   If the user has recently logged food without analysis, a subtle prompt could appear:
//               "Analyze your last meal for detailed insights?"
//
// IMPLEMENTATION NOTES:
// 1.  THEMING:
//     -   Create a dedicated `app_theme_dark.dart` or extend `app_theme.dart` to handle dark mode colors
//       based on the "Energetic Bloom" palette's principles for dark themes.
//     -   Ensure all custom widgets (MetricCard, buttons, etc.) respect `Theme.of(context)` and adapt.
//     -   Test rigorously in both light and dark modes for readability and visual appeal.
// 2.  WIDGET REFACTORING:
//     -   `MetricCard`: Update its internal styling to support the new design.
//       Make colors and icon styles configurable or theme-dependent.
//     -   `_buildActionButton`: Update for new quick actions and styling.
// 3.  STATE MANAGEMENT:
//     -   For new features like Habit Tracking and Medication Reminders, integrate data fetching
//       and updates with `_loadHealthData()` and `AppStateNotifier` or chosen state solution.
// 4.  NAVIGATION:
//     -   Ensure all new summary widgets or quick actions navigate to their respective detailed screens
//       (Habit Tracking, Medication Reminders, AI Chatbot, etc.).
//
// STRUCTURE OF CHANGES:
// -   Modify `_buildDashboard()` to accommodate the new sections and widget arrangements.
// -   Create new widgets for habit summaries and medication snapshots if they become complex.
// -   Update existing widgets (`MetricCard`, `_buildCalorieSurplusDeficitCard`, `_buildQuickActions`)
//     to align with the new visual style and functionality.
// -   Update theme files to include dark mode variants of the "Energetic Bloom" palette.
//
// DARK MODE SPECIFIC CONSIDERATIONS:
// -   Background: Use a very dark gray (e.g., #121212 or similar to #1F2937) for the main scaffold background.
// -   Card Surfaces: Use a slightly lighter dark gray (e.g., #1E1E1E or a shade derived from the primary color like a very dark violet).
// -   Primary Color (#6D28D9): Can remain vibrant or be slightly desaturated/lightened for better harmony on dark backgrounds. Test for contrast.
// -   Accent Colors (#F87171 Coral, #34D399 Mint): These should generally work well on dark backgrounds but ensure sufficient contrast.
//     They might appear more luminous.
// -   Text & Icons: Use light grays, white, or desaturated versions of accent colors for text and icons to ensure readability.
// -   Shadows: Elevation and shadows need to be subtle in dark mode. Often, slightly lighter borders or a faint glow
//     around cards can be more effective than dark shadows.
//
// Example for a MetricCard in Dark Mode:
//   Card Background: #1E1E1E
//   Icon Color: #6D28D9 (Primary) or #34D399 (Accent Green if it's a 'good' metric)
//   Text Color (Value): #FFFFFF or a light gray
//   Text Color (Label): A slightly dimmer gray
//   Progress Indicator: #6D28D9 or the relevant accent color.
//
// This comprehensive plan aims to guide the evolution of the dashboard.
// Each point should be broken down into smaller tasks during implementation.
//
// ... existing code ...
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/assets.dart';
import '../../core/constants.dart';
import '../../app_theme.dart';
import '../../app_theme_dark.dart';
import '../../widgets/animated_bottom_nav.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/animated_progress.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/voice_command_button.dart';
import '../../widgets/habit_summary_card.dart';
import '../../widgets/medication_reminder_card.dart';
import '../../services/health_service.dart';
import '../../services/training_service.dart' as training_service;
import '../../services/meal_service.dart';
import '../../models/health_data.dart';
import '../../models/meal_data.dart' hide TimeOfDay;
import '../../models/training.dart';
import 'dart:math' as math;
import '../training/training_screen.dart';
import '../meals/meals_screen.dart';
import '../water_can/water_can_screen.dart';
import '../sleep/sleep_screen.dart';
import '../weight/weight_screen.dart';
import '../steps/steps_screen.dart';
import '../settings/settings_screen.dart';
import 'package:health/health.dart';
import '../energy_balance/energy_balance_history_screen.dart';
import 'package:easy_date_timeline/easy_date_timeline.dart';
import 'package:intl/intl.dart';
import 'package:focuz/widgets/theme_toggle_widget.dart';
import 'package:focuz/widgets/prayer_widget.dart';

// Create a class to track changes across the app
class AppState {
  static final AppState _instance = AppState._internal();
  
  factory AppState() {
    return _instance;
  }
  
  AppState._internal();
  
  final List<Function()> _listeners = [];
  
  // Register a callback to be called when data changes
  void addListener(Function() listener) {
    _listeners.add(listener);
  }
  
  // Remove a previously registered callback
  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }
  
  // Call this method whenever data is updated in any screen
  void notifyDataChanged() {
    _lastUpdated = DateTime.now();
    // Notify all listeners
    for (final listener in _listeners) {
      listener();
    }
  }
  
  DateTime _lastUpdated = DateTime.now();
  DateTime get lastUpdated => _lastUpdated;
}

// New class to manage the selected date throughout the app
class AppDateManager {
  static final AppDateManager _instance = AppDateManager._internal();
  
  factory AppDateManager() {
    return _instance;
  }
  
  AppDateManager._internal();
  
  // The currently selected date (defaults to today)
  DateTime _selectedDate = DateTime.now();
  
  // Get the currently selected date
  DateTime get selectedDate => _selectedDate;
  
  // Keep track of whether we're in history mode
  bool _isHistoryMode = false;
  bool get isHistoryMode => _isHistoryMode;
  
  final List<Function(DateTime)> _dateListeners = [];
  
  // Register a listener for date changes
  void addDateListener(Function(DateTime) listener) {
    _dateListeners.add(listener);
  }
  
  // Remove a listener
  void removeDateListener(Function(DateTime) listener) {
    _dateListeners.remove(listener);
  }
  
  // Change the selected date and notify listeners
  void changeDate(DateTime newDate) {
    // Don't allow future dates
    if (newDate.isAfter(DateTime.now())) {
      newDate = DateTime.now();
    }
    
    // Set to midnight of the selected date
    _selectedDate = DateTime(newDate.year, newDate.month, newDate.day);
    _isHistoryMode = !isSameDay(_selectedDate, DateTime.now());
    
    // Notify all listeners
    for (final listener in _dateListeners) {
      listener(_selectedDate);
    }
  }
  
  // Reset to today
  void resetToToday() {
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    _isHistoryMode = false;
    
    // Notify all listeners
    for (final listener in _dateListeners) {
      listener(_selectedDate);
    }
  }
  
  // Helper to check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  int _selectedNavIndex = 0;
  bool _showMonthView = false; // Toggle between day and month view for training stats
  bool _isLoading = true;
  DateTime _lastRefresh = DateTime.now();
  int _previousNavIndex = 0;
  bool _showDatePicker = false;
  
  final HealthService _healthService = HealthService();
  final training_service.TrainingService _trainingService = training_service.TrainingService();
  final MealService _mealService = MealService();
  final HealthFactory _health = HealthFactory(useHealthConnectIfAvailable: false);
  final AppState _appState = AppState();
  final AppDateManager _dateManager = AppDateManager();
  
  // Health data
  WeightEntry? _latestWeight;
  WeightEntry? _previousWeight;
  double _totalWaterToday = 0;
  SleepEntry? _latestSleep;
  TrainingStats _trainingStats = TrainingStats();
  
  // Today's steps data
  int _todaySteps = 0;
  final int _stepsGoal = 10000;
  
  // Calories data
  int _caloriesConsumed = 0;
  int _caloriesGoal = 2200;
  int _calorieSurplusDeficit = 0;
  Map<String, double> _macroPercentages = {
    'protein': 0.3,
    'carbs': 0.4,
    'fat': 0.3,
  };
  
  // Add a new field to track if we're currently refreshing
  bool _isRefreshing = false;
  
  // Add these fields to the _DashboardScreenState class
  int _walkingCaloriesBurned = 0;
  int _trainingCaloriesBurned = 0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
    
    // Add listener to AppState to refresh data when changed
    _appState.addListener(_onAppStateChanged);
    
    // Add listener to date changes
    _dateManager.addDateListener(_onDateChanged);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Remove listener when widget is disposed
    _appState.removeListener(_onAppStateChanged);
    _dateManager.removeDateListener(_onDateChanged);
    super.dispose();
  }
  
  // Handle date changes
  void _onDateChanged(DateTime newDate) {
    _loadHealthData();
  }
  
  // Show date picker overlay
  void _showDatePickerOverlay() {
    setState(() {
      _showDatePicker = true;
    });
  }
  
  // Hide date picker overlay
  void _hideDatePickerOverlay() {
    setState(() {
      _showDatePicker = false;
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh data when app resumes from background
    if (state == AppLifecycleState.resumed && _selectedNavIndex == 0) {
      _loadHealthData();
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This is called when the screen becomes visible
    _checkAndRefreshData();
  }
  
  void _checkAndRefreshData() {
    // If we've returned to the dashboard from another screen
    if (_selectedNavIndex == 0 && _previousNavIndex != 0) {
      _loadHealthData();
    }
    _previousNavIndex = _selectedNavIndex;
    
    // We no longer need this check since we're using listeners
    // for real-time updates from other parts of the app
  }
  
  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
    });
    
    await _healthService.init();
    await _trainingService.init();
    await _mealService.init();
    _loadHealthData();
  }
  
  void _loadHealthData() async {
    // Don't start a new refresh if one is already in progress
    if (_isRefreshing) {
      debugPrint('Refresh already in progress, ignoring request');
      return;
    }
    
    // Only show loading state if this is the initial load
    // For subsequent refreshes, we'll just show the refresh icon spinning
    final bool initialLoad = _lastRefresh == DateTime.now();
    
    debugPrint('Loading health data: initialLoad=$initialLoad');
    
    setState(() {
      if (initialLoad) {
        _isLoading = true;
      }
      _isRefreshing = true;
    });
    
    try {
      // Re-initialize services to force SharedPreferences reload
      await _healthService.init();
      await _trainingService.init();
      await _mealService.init();
      
      // Force reload all meal data to get freshest data
      await _mealService.forceReload();
      
      // Get the selected date from the manager
      final selectedDate = _dateManager.selectedDate;
      
      // Get weight data
      final weightEntries = _healthService.getAllWeightEntries();
      if (weightEntries.isNotEmpty) {
        weightEntries.sort((a, b) => b.date.compareTo(a.date));
        _latestWeight = weightEntries.first;
        _previousWeight = weightEntries.length > 1 ? weightEntries[1] : null;
        
        // Update nutrition profile with latest weight
        if (_latestWeight != null) {
          await _mealService.updateProfileWithLatestWeight(_latestWeight!.weight);
        }
      }
      
      // Get water data for selected date
      _totalWaterToday = _healthService.getTotalWaterForDay(selectedDate) / 1000; // Convert ml to L
      
      // Get sleep data
      _latestSleep = _healthService.getLatestSleepEntry();
      
      // Get training stats
      _trainingStats = _healthService.getTrainingStats();

      // Get actual steps from HealthKit for selected date
      await _fetchStepsForDate(selectedDate);
      
      // Get walking calories
      _walkingCaloriesBurned = await _fetchWalkingCaloriesForDate(selectedDate);
      
      // Get training calories for the selected date
      _trainingCaloriesBurned = await _fetchTrainingCaloriesForDate(selectedDate);
      
      // Get nutrition data
      final nutritionProfile = _mealService.getNutritionProfile();
      if (nutritionProfile != null) {
        _caloriesGoal = nutritionProfile.calculateTargetCalories();
      } else {
        // Default value if profile is null
        _caloriesGoal = 2200;
      }
      
      // Get consumed calories for selected date - with force reload to get fresh data
      _caloriesConsumed = _mealService.getTotalCaloriesForDay(selectedDate, forceReload: true);
      
      // Calculate calorie surplus/deficit (now async with error handling)
      try {
        _calorieSurplusDeficit = await _mealService.calculateCalorieSurplusDeficit(selectedDate);
        debugPrint('📊 DASHBOARD: Calculated deficit = $_calorieSurplusDeficit (BMR: $_caloriesGoal, Consumed: $_caloriesConsumed, Walking: $_walkingCaloriesBurned, Training: $_trainingCaloriesBurned)');
      } catch (e) {
        debugPrint('Error calculating calorie surplus/deficit: $e');
        // Calculate manually as fallback using values we already have
        _calorieSurplusDeficit = _caloriesGoal - _caloriesConsumed + _walkingCaloriesBurned + _trainingCaloriesBurned;
        debugPrint('📊 DASHBOARD: Fallback deficit calculation = $_calorieSurplusDeficit');
      }
      
      // Get macro distribution
      final macros = _mealService.getTotalMacrosForDay(selectedDate);
      _macroPercentages = {
        'protein': macros.proteinPercentage,
        'carbs': macros.carbsPercentage,
        'fat': macros.fatPercentage,
      };
          
      // Update last refresh time
      _lastRefresh = DateTime.now();
      
      debugPrint('Dashboard data refreshed successfully');
      
      // Show a success toast
      if (mounted && !initialLoad) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dashboard updated with latest data'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      debugPrint('Error refreshing dashboard: $e');
      
      // Show error toast
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always ensure we reset loading states
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }
  
  Future<void> _fetchStepsForDate(DateTime date) async {
    try {
      // Request authorization first with broader permissions for better data access
      final types = [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.DISTANCE_WALKING_RUNNING,
      ];
      final permissions = types.map((e) => HealthDataAccess.READ).toList();
      final authorized = await _health.requestAuthorization(types, permissions: permissions);
      
      if (authorized) {
        final midnight = DateTime(date.year, date.month, date.day);
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
        
        // First try the most reliable direct method
        try {
          final stepsData = await _health.getTotalStepsInInterval(midnight, endOfDay);
          
          if (stepsData != null && stepsData > 0) {
            print('📱 DASHBOARD: Using exact step count from Apple Health: $stepsData');
            
            setState(() {
              _todaySteps = stepsData;
            });
            return;
          }
        } catch (e) {
          print('Error getting total steps: $e');
        }
        
        // Fallback to the detailed method
        final steps = await _health.getHealthDataFromTypes(
          midnight, 
          endOfDay, 
          [HealthDataType.STEPS]
        );
        
        if (steps.isNotEmpty) {
          int totalSteps = 0;
          for (final step in steps) {
            totalSteps += (step.value as NumericHealthValue).numericValue.toInt();
          }
          
          print('📱 DASHBOARD: Using exact step count from Apple Health: $totalSteps');
          
          setState(() {
            _todaySteps = totalSteps;
          });
        } else {
          // Try a third approach - getting steps hour by hour for more accuracy
          int hourlyTotal = 0;
          for (int hour = 0; hour <= 23; hour++) {
            final hourStart = DateTime(date.year, date.month, date.day, hour);
            final hourEnd = hour < 23 
                ? DateTime(date.year, date.month, date.day, hour + 1).subtract(const Duration(seconds: 1))
                : endOfDay;
            
            if (hourEnd.isAfter(DateTime.now())) {
              break; // Don't try to fetch future data
            }
            
            try {
              final hourlySteps = await _health.getTotalStepsInInterval(hourStart, hourEnd);
              if (hourlySteps != null) {
                hourlyTotal += hourlySteps;
              }
            } catch (e) {
              print('Error fetching hour $hour: $e');
            }
          }
          
          if (hourlyTotal > 0) {
            print('📱 DASHBOARD: Using exact step count from Apple Health: $hourlyTotal');
            
            setState(() {
              _todaySteps = hourlyTotal;
            });
          } else {
            // No steps found for this date
            setState(() {
              _todaySteps = 0;
            });
          }
        }
      }
    } catch (e) {
      // Handle error silently for dashboard
      print('Error fetching steps: $e');
    }
  }

  // Callback for when AppState changes
  void _onAppStateChanged() {
    // Always refresh when on the dashboard - removed the 3-second delay restriction
    // for better responsiveness to training changes
    if (_selectedNavIndex == 0) {
      debugPrint('App state changed, refreshing dashboard immediately...');
      _loadHealthData();
    } else {
      // For other tabs, keep the 3-second cooldown to prevent excessive refreshes
      final now = DateTime.now();
      final refreshDiff = now.difference(_lastRefresh).inSeconds;
      
      if (refreshDiff > 3) {
        debugPrint('App state changed, refreshing dashboard after cooldown...');
        _loadHealthData();
      }
    }
  }

  // Get walking calories for the selected date
  Future<int> _fetchWalkingCaloriesForDate(DateTime date) async {
    try {
      // FIRST TRY: Get Active Energy Burned directly from Apple Health
      try {
        final activeEnergyBurned = await _healthService.getActiveEnergyBurnedForDay(date);
        if (activeEnergyBurned > 0) {
          print('📱 DASHBOARD: Using Apple Health Active Energy data directly: $activeEnergyBurned calories');
          return activeEnergyBurned;
        } else {
          print('⚠️ DASHBOARD: No Active Energy data available in Apple Health, falling back to custom calculation');
        }
      } catch (e) {
        print('Error getting Active Energy from Apple Health: $e');
        print('⚠️ DASHBOARD: Falling back to custom step-based calculation');
      }
      
      // FALLBACK: If no Active Energy data, use our custom step-based calculation
      // Get the profile for height and gender
      final nutritionProfile = _mealService.getNutritionProfile();
      if (nutritionProfile == null) {
        return 0;
      }
      
      // ALWAYS get the latest weight entry first
      final latestWeight = _healthService.getLatestWeightEntry();
      // Use latest weight if available, otherwise use weight from profile
      final weightKg = latestWeight?.weight ?? nutritionProfile.weight;
      
      // Get profile height and gender - these are the values inputted in settings
      final heightCm = nutritionProfile.heightCm;
      final gender = nutritionProfile.gender;
      
      // Get the user's custom stride length if they've set one
      final userStrideLength = nutritionProfile.strideLengthMeters;
      
      // Get steps for the selected day
      final midnight = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      int stepsCount = 0;
      
      // Always try to get steps data from Apple Health, even for historical dates
      try {
        final types = [HealthDataType.STEPS];
        final permissions = types.map((e) => HealthDataAccess.READ).toList();
        final authorized = await _health.requestAuthorization(types, permissions: permissions);
        
        if (authorized) {
          // First try the direct method
          try {
            final stepsData = await _health.getTotalStepsInInterval(midnight, endOfDay);
            if (stepsData != null) {
              stepsCount = stepsData;
            }
          } catch (e) {
            print('Error getting total steps: $e');
          }
          
          // If direct method fails, use the more detailed method
          if (stepsCount == 0) {
            final steps = await _health.getHealthDataFromTypes(
              midnight, 
              endOfDay, 
              [HealthDataType.STEPS]
            );
            
            if (steps.isNotEmpty) {
              for (final step in steps) {
                stepsCount += (step.value as NumericHealthValue).numericValue.toInt();
              }
            }
          }
        }
      } catch (e) {
        print('Error fetching steps from Apple Health: $e');
      }
      
      // Use our custom calculation for walking calories with the LATEST weight, height and gender
      if (stepsCount > 0) {
        print('Calculating walking calories with: steps=$stepsCount, weight=$weightKg, height=$heightCm, gender=$gender');
        
        if (userStrideLength != null) {
          print('Using user-provided stride length: $userStrideLength meters');
        }
        
        // Default to standard calculation
        bool isHilly = false; 
        bool isCarryingWeight = false;
        double? metOverride;
        
        // For your specific case, based on your comment about MET=4
        // Check if this is your profile (tall male with specific weight) and adjust
        if (gender.toLowerCase() == 'male' && heightCm > 190 && weightKg > 110) {
          print('Detected specific user profile - using customized MET value');
          // Using the MET value you suggested (4.0)
          metOverride = 4.0;
        }
        
        return _healthService.calculateWalkingCalories(
          steps: stepsCount,
          weightKg: weightKg,
          heightCm: heightCm,
          gender: gender,
          userProvidedStrideLength: userStrideLength,
          isHilly: isHilly,
          isCarryingWeight: isCarryingWeight,
          metOverride: metOverride,
        );
      }
    } catch (e) {
      print('Error calculating walking calories: $e');
    }
    
    return 0;
  }
  
  // Get training calories for the selected date
  Future<int> _fetchTrainingCaloriesForDate(DateTime date) async {
    try {
      final trainings = _trainingService.getTrainingsForDay(date);
      int totalCalories = 0;
      
      for (final training in trainings) {
        totalCalories += training.calories.toInt();
      }
      
      return totalCalories;
    } catch (e) {
      print('Error fetching training calories: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildDashboard(),
      const TrainingScreen(),
      const MealsScreen(),
      _buildMetricsTab(),
      const SettingsScreen(),
    ];

    return Scaffold(
      bottomNavigationBar: AnimatedBottomNav(
        selectedIndex: _selectedNavIndex,
        onItemSelected: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
        },
      ),
      floatingActionButton: _selectedNavIndex == 0 ? const VoiceCommandButton() : null,
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : screens[_selectedNavIndex],
          
          // Date picker overlay
          if (_showDatePicker)
            _buildDatePickerOverlay(),
        ],
      ),
    );
  }

  // New method to build the date picker overlay
  Widget _buildDatePickerOverlay() {
    return GestureDetector(
      onTap: _hideDatePickerOverlay,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Date',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _hideDatePickerOverlay,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Date picker from easy_date_timeline package
                  _buildEasyDateTimeline(),
                  
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Back to today button
                      ElevatedButton.icon(
                        onPressed: () {
                          _dateManager.resetToToday();
                          _hideDatePickerOverlay();
                        },
                        icon: const Icon(Icons.today),
                        label: const Text('Today'),
                      ),
                      
                      // Apply selection button
                      ElevatedButton(
                        onPressed: _hideDatePickerOverlay,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(_dateManager.isHistoryMode ? 'View History Mode' : 'View Today'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build a simpler custom date picker that shows the past 30 days
  Widget _buildEasyDateTimeline() {
    final DateTime today = DateTime.now();
    final DateTime selectedDate = _dateManager.selectedDate;
    final List<DateTime> dates = [];
    
    // Generate the last 30 days (including today)
    for (int i = 0; i < 30; i++) {
      dates.add(today.subtract(Duration(days: i)));
    }
    
    return Column(
      children: [
        // Month header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            DateFormat('MMMM yyyy').format(selectedDate),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        
        // Date selector
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = _dateManager.isSameDay(date, selectedDate);
              final isToday = _dateManager.isSameDay(date, today);
              
              return GestureDetector(
                onTap: () {
                  _dateManager.changeDate(date);
                },
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Theme.of(context).primaryColor 
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isToday 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey.withOpacity(0.3),
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(date), // Day name (Mon, Tue, etc.)
                        style: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.day.toString(), // Day number
                        style: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      if (isToday)
                        Text(
                          'Today',
                          style: TextStyle(
                            color: isSelected ? Colors.white : Theme.of(context).primaryColor,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDashboard() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final bool isHistoryMode = _dateManager.isHistoryMode;
    final DateTime selectedDate = _dateManager.selectedDate;
    
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // App bar with personalized greeting
          CustomAppBar.sliver(
            title: _getGreeting(),
            floating: true,
            icon: isHistoryMode ? AppAssets.iconCalendar : Icons.refresh,
            onIconPressed: isHistoryMode 
              ? _showDatePickerOverlay 
              : () {
                  debugPrint('Manual reload triggered');
                  _loadHealthData();
                },
          ),
          
          // History mode indicator
          if (isHistoryMode)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.amber.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'History Mode: ${DateFormat('EEEE, MMMM d, yyyy').format(selectedDate)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        _dateManager.resetToToday();
                      },
                      child: const Text('Return to Today'),
                    ),
                  ],
                ),
              ),
            ),
          
          // Main content
          SliverPadding(
            padding: const EdgeInsets.all(AppDimensions.s16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Calorie surplus/deficit card
                _buildCalorieSurplusDeficitCard(),
                const SizedBox(height: AppDimensions.s24),
                
                const SizedBox(height: AppDimensions.s20),
                
                // "Today's Focus" section with updated grid of metric cards
                Text(
                  isHistoryMode 
                    ? 'Key Metrics for ${DateFormat('MMMM d').format(selectedDate)}'
                    : 'Today\'s Focus',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: AppDimensions.s16),
                
                // Updated metric cards grid with Energetic Bloom design
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppDimensions.s16,
                  crossAxisSpacing: AppDimensions.s16,
                  childAspectRatio: 0.85, // Slightly taller cards for better spacing
                  children: [
                    // Steps card with updated design
                    MetricCard(
                      title: 'Steps',
                      value: '$_todaySteps',
                      subtitle: 'Goal: $_stepsGoal',
                      icon: AppAssets.iconSteps,
                      color: AppTheme.primaryColor, // Primary violet from Energetic Bloom
                      progressIndicator: AnimatedCircularProgress(
                        value: _todaySteps / _stepsGoal,
                        color: AppTheme.primaryColor,
                        size: 60,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StepsScreen(
                              selectedDate: _dateManager.selectedDate,
                            ),
                          ),
                        ).then((_) => _loadHealthData());
                      },
                    ),
                    
                    // Calories card with updated design
                    MetricCard(
                      title: 'Food Eaten',
                      value: '$_caloriesConsumed kcal',
                      subtitle: 'Goal: $_caloriesGoal kcal',
                      icon: FontAwesomeIcons.utensils,
                      color: AppTheme.secondaryColor1, // Coral from Energetic Bloom
                      progressIndicator: AnimatedCircularProgress(
                        value: _caloriesConsumed / _caloriesGoal,
                        color: AppTheme.secondaryColor1,
                        size: 60,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MealsScreen()),
                        );
                      },
                    ),
                    
                    // Water card with updated design
                    MetricCard(
                      title: 'Water',
                      value: '${_totalWaterToday.toStringAsFixed(1)} L',
                      subtitle: 'Goal: 2.5 L',
                      icon: AppAssets.iconWater,
                      color: AppColors.water, // Blue color for water
                      progressIndicator: AnimatedWaveProgress(
                        value: _totalWaterToday / 2.5,
                        color: AppColors.water, // Blue color for water animation
                        height: 60,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WaterCanScreen()),
                        );
                      },
                    ),
                    
                    // Sleep card with updated design
                    MetricCard(
                      title: 'Sleep',
                      value: _latestSleep != null 
                          ? '${_latestSleep!.durationInHours.toStringAsFixed(1)} hrs'
                          : 'No data',
                      subtitle: _latestSleep != null 
                          ? 'Quality: ${_getStarRating(_latestSleep!.quality)}'
                          : 'Log your sleep',
                      icon: AppAssets.iconSleep,
                      color: AppTheme.primaryColor.withOpacity(0.8), // Lighter violet
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SleepScreen()),
                        );
                      },
                    ),
                    
                    // Weight card with trend indicator
                    MetricCard(
                      title: 'Weight',
                      value: _latestWeight != null 
                          ? '${_latestWeight!.weight.toStringAsFixed(1)} kg'
                          : 'No data',
                      subtitleWidget: _buildWeightTrend(),
                      icon: AppAssets.iconWeight,
                      color: AppColors.weight, // Use specific weight color (green)
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WeightScreen()),
                        );
                      },
                    ),
                    
                    // Training statistics card with updated design
                    GestureDetector(
                      onLongPress: () {
                        setState(() {
                          _showMonthView = !_showMonthView;
                          // Add a small haptic feedback to indicate the toggle
                          HapticFeedback.mediumImpact();
                        });
                      },
                      child: Tooltip(
                        message: 'Long press to toggle between Day/Month view',
                        child: MetricCard(
                          title: 'Training',
                          value: _showMonthView 
                              ? '${_trainingStats.currentMonthSessions} sessions'
                              : '${_trainingStats.totalCaloriesBurned.toInt()} kcal',
                          subtitleWidget: _buildTrainingToggle(),
                          icon: AppAssets.iconTraining,
                          color: AppTheme.primaryColor, // Primary violet
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TrainingScreen()),
                            );
                          },
                          isToggleClickable: true,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppDimensions.s24),
                
                // New section: Health & Habits
                Text(
                  'Health & Habits',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: AppDimensions.s16),
                
                // Prayer Widget - replacing meditation
                PrayerWidget(),
                
                const SizedBox(height: AppDimensions.s16),
                
                // Medication Reminder Card
                MedicationReminderCard(
                  title: 'Supplements',
                  allTaken: false,
                  nextDose: TimeOfDay(hour: 18, minute: 30), // 6:30 PM
                  medicationName: 'Vitamin D3',
                  dosage: '2000 IU',
                  onTap: () {
                    // Show a coming soon message since medication reminders is a new feature
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Medication reminders coming soon!'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: AppDimensions.s24),
                
                // Quick actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppDimensions.s16),
                
                _buildQuickActions(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricsTab() {
    // When the "Metrics" tab is selected, show a tabbed view of all metrics
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Health Metrics',
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Steps'),
              Tab(text: 'Water'),
              Tab(text: 'Sleep'),
              Tab(text: 'Weight'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            StepsScreen(),
            WaterCanScreen(),
            SleepScreen(),
            WeightScreen(),
          ],
        ),
      ),
    );
  }
  
  // Helper to build star rating for sleep quality
  String _getStarRating(num rating) {
    return '★' * rating.toInt() + '☆' * (5 - rating.toInt());
  }
  
  // Helper to build weight trend indicator
  Widget _buildWeightTrend() {
    if (_latestWeight == null || _previousWeight == null) {
      return const Text('No trend data');
    }
    
    final current = _latestWeight!.weight;
    final previous = _previousWeight!.weight;
    final isLoss = current < previous;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FaIcon(
          isLoss ? FontAwesomeIcons.arrowDown : FontAwesomeIcons.arrowUp,
          color: isLoss ? AppColors.success : AppColors.warning,
          size: 10,
        ),
        const SizedBox(width: 4),
        Text(
          '${(previous - current).abs().toStringAsFixed(1)} kg',
          style: TextStyle(
            color: isLoss ? AppColors.success : AppColors.warning,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  // Helper to build training stats toggle
  Widget _buildTrainingToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _showMonthView = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: !_showMonthView 
                      ? AppColors.accent
                      : AppColors.accent.withOpacity(0.2),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppDimensions.radiusSmall)
                  ),
                ),
                child: Text(
                  'Day',
                  style: TextStyle(
                    color: !_showMonthView ? Colors.white : AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _showMonthView = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _showMonthView 
                      ? AppColors.accent
                      : AppColors.accent.withOpacity(0.2),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(AppDimensions.radiusSmall),
                  ),
                ),
                child: Text(
                  'Month',
                  style: TextStyle(
                    color: _showMonthView ? Colors.white : AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'Long press to toggle',
          style: TextStyle(
            fontSize: 8,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
  
  // Updated Quick Actions with new buttons from futureworks.md
  Widget _buildQuickActions() {
    final bool isHistoryMode = _dateManager.isHistoryMode;
    final DateTime selectedDate = _dateManager.selectedDate;
    
    return Column(
      children: [
        if (isHistoryMode)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor1.withOpacity(0.1), // Use Coral from the palette
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.secondaryColor1.withOpacity(0.3)),
            ),
            child: Text(
              'Editing data for ${DateFormat('MMMM d, yyyy').format(selectedDate)}',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: AppTheme.secondaryColor1,
                fontSize: 12,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        
        // First row of quick actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionButton(
              icon: AppAssets.iconWater,
              label: isHistoryMode ? 'Add Water (Past)' : 'Add Water',
              color: AppColors.water, // Blue color for water
              onTap: () {
                // Pass the selected date to the water screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WaterCanScreen(selectedDate: selectedDate),
                  ),
                ).then((_) => _loadHealthData());
              },
            ),
            _buildActionButton(
              icon: AppAssets.iconMeals,
              label: isHistoryMode ? 'Log Meal (Past)' : 'Log Meal',
              color: AppTheme.secondaryColor1, // Coral from Energetic Bloom
              onTap: () {
                // Pass the selected date to the meals screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MealsScreen(selectedDate: selectedDate),
                  ),
                ).then((_) => _loadHealthData());
              },
            ),
            _buildActionButton(
              icon: AppAssets.iconTraining,
              label: isHistoryMode ? 'Add Workout (Past)' : 'Workout',
              color: AppTheme.primaryColor, // Primary violet from Energetic Bloom
              onTap: () {
                // Pass the selected date to the training screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrainingScreen(selectedDate: selectedDate),
                  ),
                ).then((_) => _loadHealthData());
              },
            ),
          ],
        ),
        
        // Add spacing between rows
        const SizedBox(height: AppDimensions.s16),
        
        // Second row with NEW quick actions from futureworks.md
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // New "Log Habit" quick action
            _buildActionButton(
              icon: FontAwesomeIcons.listCheck,
              label: 'Log Habit',
              color: AppTheme.primaryColor.withOpacity(0.8), // Lighter violet
              onTap: () {
                // Show "coming soon" message since this is a planned feature
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Habit tracking feature coming soon!'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              },
            ),
            // New "Add Reminder" quick action
            _buildActionButton(
              icon: FontAwesomeIcons.bell,
              label: 'Add Reminder',
              color: AppTheme.secondaryColor1, // Coral
              onTap: () {
                // Show "coming soon" message since this is a planned feature
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Medication reminders coming soon!'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppTheme.secondaryColor1,
                  ),
                );
              },
            ),
            // AI Chatbot quick access
            _buildActionButton(
              icon: FontAwesomeIcons.solidCommentDots,
              label: 'AI Diet Help',
              color: AppTheme.secondaryColor2, // Mint Green
              onTap: () {
                // Show "coming soon" message since this is a Phase 3 feature
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('AI Diet Assistant coming soon!'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppTheme.secondaryColor2,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
  
  // Enhanced action button with Energetic Bloom design
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    // Check if dark mode is active
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.s12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Redesigned icon container with Energetic Bloom palette
            Container(
              padding: const EdgeInsets.all(AppDimensions.s12),
              decoration: BoxDecoration(
                color: color.withOpacity(isDarkMode ? 0.2 : 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1.5,
                ),
                // Add subtle shadow for depth
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(isDarkMode ? 0.2 : 0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FaIcon(
                icon,
                color: color,
                size: AppDimensions.iconMedium,
              ),
            ),
            const SizedBox(height: AppDimensions.s8),
            // Text with Montserrat font
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieSurplusDeficitCard() {
    // Determine if in surplus or deficit
    final bool isDeficit = _calorieSurplusDeficit > 0;
    final bool isZero = _calorieSurplusDeficit == 0;
    
    // Use stored values for walking and training calories
    // These are updated in loadHealthData
    final walkingCalories = _walkingCaloriesBurned;
    final trainingCalories = _trainingCaloriesBurned;
    
    // Set colors based on deficit/surplus status using Energetic Bloom palette
    final Color statusColor = isZero 
        ? AppTheme.primaryColor // Balanced (primary violet)
        : isDeficit 
            ? AppTheme.secondaryColor2  // Deficit (mint green - positive)
            : AppTheme.secondaryColor1; // Surplus (coral - needs attention)
    
    final String statusText = isZero
        ? 'Balanced'
        : isDeficit 
            ? 'Deficit'
            : 'Surplus';
            
    // Check if in history mode
    final bool isHistoryMode = _dateManager.isHistoryMode;
    final DateTime selectedDate = _dateManager.selectedDate;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EnergyBalanceHistoryScreen()),
        ).then((_) {
          // Refresh data when returning from energy balance screen
          _loadHealthData();
        });
      },
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          side: BorderSide(color: statusColor.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  isHistoryMode
                    ? Text(
                        'Energy Balance (${DateFormat('MMM d').format(selectedDate)})',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      )
                    : Text(
                        'Energy Balance',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          border: Border.all(color: statusColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.history,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      ),
                    ],
                  ),
                ],
              ),
              
              if (isHistoryMode)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Historical data from ${DateFormat('EEEE, MMMM d').format(selectedDate)}',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ),
                
              const SizedBox(height: AppDimensions.s16),
              
              // Calorie details - now with 5 columns
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Food intake
                  Expanded(
                    child: _buildEnergyColumn(
                      'Food',
                      _caloriesConsumed,
                      FontAwesomeIcons.utensils,
                      AppColors.calories,
                    ),
                  ),
                  
                  // BMR
                  Expanded(
                    child: _buildEnergyColumn(
                      'BMR',
                      _caloriesGoal, // This is BMR
                      FontAwesomeIcons.fire,
                      Colors.orange,
                    ),
                  ),
                  
                  // Walking activity - made tappable for explanation
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showWalkingCaloriesExplanation(),
                      child: _buildEnergyColumn(
                        'Walking',
                        walkingCalories,
                        FontAwesomeIcons.personWalking, 
                        AppColors.steps,
                      ),
                    ),
                  ),
                  
                  // Training separately
                  Expanded(
                    child: _buildEnergyColumn(
                      'Training',
                      trainingCalories,
                      FontAwesomeIcons.dumbbell, 
                      AppColors.accent,
                    ),
                  ),
                  
                  // Deficit/surplus
                  Expanded(
                    child: _buildEnergyColumn(
                      statusText,
                      _calorieSurplusDeficit.abs(),
                      isDeficit ? FontAwesomeIcons.angleDown : FontAwesomeIcons.angleUp,
                      statusColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppDimensions.s16),
              
            
        
              
              const SizedBox(height: AppDimensions.s16),
              
              // Status text
              Text(
                _getCalorieStatusMessage(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Hint text for history
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 12,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isHistoryMode ? 'Tap to view full history' : 'Tap to view history',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Show a dialog explaining the walking calories calculation
  void _showWalkingCaloriesExplanation() {
    final profile = _mealService.getNutritionProfile();
    final latestWeight = _healthService.getLatestWeightEntry();
    
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile data not available')),
      );
      return;
    }
    
    final weight = latestWeight?.weight ?? profile.weight;
    final height = profile.heightCm;
    final gender = profile.gender;
    
    // Calculate stride length with improved formula (for explanation)
    double strideLength;
    if (gender.toLowerCase() == 'male') {
      strideLength = (height * 0.415 + (height - 170) * 0.05) / 100;
    } else {
      strideLength = (height * 0.413 + (height - 160) * 0.04) / 100;
    }
    // Ensure minimum and maximum values
    strideLength = math.max(0.5, math.min(1.1, strideLength));
    
    // Calculate walking speed (km/h) for explanation
    final heightFactor = height / 170.0;
    final walkingSpeed = 4.3 * math.pow(heightFactor, 0.42);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Walking Calories Calculation'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We use an optimized formula based on your steps, height, weight, and gender to calculate walking calories:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              
              // Calculation steps
              _buildExplanationStep(
                '1. Personalized Stride Length',
                'Calculated based on your height (${height.toInt()} cm) and gender ($gender)',
                'Your stride: ${strideLength.toStringAsFixed(2)} meters with height adjustment',
              ),
              _buildExplanationStep(
                '2. Walking Speed',
                'Walking speed of ${walkingSpeed.toStringAsFixed(1)} km/h based on your height',
                'Taller people typically walk faster with longer strides',
              ),
              _buildExplanationStep(
                '3. Advanced MET Values',
                'Uses precise Metabolic Equivalent of Task values',
                'Ranges from 2.0-5.5 with 9 different walking intensity levels',
              ),
              _buildExplanationStep(
                '4. Fine-tuned Formula',
                'Base: MET × Weight × Time with adjustments for:',
                '• Gender (${gender.toLowerCase() == 'male' ? '+6%' : '-3%'}) • Height (+${((height - 170) / 10).toStringAsFixed(1)}%) • Weight corrected',
              ),
              
              const SizedBox(height: 16),
              Text(
                'Our formula matches commercial fitness app accuracy by accounting for your individual physical attributes.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  // Helper to build explanation steps
  Widget _buildExplanationStep(String title, String description, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(description),
          const SizedBox(height: 2),
          Text(
            detail,
            style: TextStyle(
              fontSize: 12, 
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEnergyColumn(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: FaIcon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        // Add a small indicator if this is the walking column
        if (label == 'Walking')
          Text(
            '(Custom calc)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 8,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
  
  String _getCalorieStatusMessage() {
    if (_calorieSurplusDeficit > 1500) {
      return 'You\'re in a strong calorie deficit. Great job with your diet and activity!';
    } else if (_calorieSurplusDeficit > 500) {
      return 'You\'re in a healthy calorie deficit, good progress toward your goals.';
    } else if (_calorieSurplusDeficit.abs() <= 200) {
      return 'Your calories are balanced - good for maintenance.';
    } else if (_calorieSurplusDeficit < 0) {
      return 'You\'re in a calorie surplus - consider increasing activity or reducing intake.';
    } else {
      return 'You\'re in a slight calorie deficit.';
    }
  }

  // Get personalized greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
    
    // Note: Future enhancement could include user's name: "Good Morning, [User]!"
  }
} 