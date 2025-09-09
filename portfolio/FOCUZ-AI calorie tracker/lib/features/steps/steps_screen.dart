import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:health/health.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../core/assets.dart';
import '../../core/constants.dart';
import '../../widgets/animated_progress.dart';
import '../dashboard/dashboard_screen.dart'; // Import AppDateManager
import '../../models/health_data.dart';
import '../../services/health_service.dart';
import '../../widgets/custom_app_bar.dart';

class StepsScreen extends StatefulWidget {
  final DateTime? selectedDate; // Add selectedDate parameter
  
  const StepsScreen({super.key, this.selectedDate});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> with TickerProviderStateMixin {
  late AnimationController _walkingAnimationController;
  late AnimationController _pulseAnimationController;
  
  // Health data
  final HealthFactory _health = HealthFactory(useHealthConnectIfAvailable: false);
  
  // Steps data
  int _currentSteps = 0;
  final int _stepsGoal = 10000;
  bool _isLoading = true;
  String _errorMessage = '';
  
  // Weekly steps data
  final List<Map<String, dynamic>> _weeklySteps = [];
  
  // Date management
  late AppDateManager _dateManager;
  late DateTime _selectedDate;
  bool _isHistoryMode = false;
  bool _showDatePicker = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize date manager
    _dateManager = AppDateManager();
    
    // Set selected date (from parameter or current date)
    _selectedDate = widget.selectedDate ?? _dateManager.selectedDate;
    _isHistoryMode = !_isSameDay(_selectedDate, DateTime.now());
    
    // Initialize the walking animation controller
    _walkingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    // Create a separate controller for pulsing animation
    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Fetch health data
    _fetchHealthData();
  }
  
  @override
  void dispose() {
    _walkingAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  // Helper to check if two dates are the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
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
  
  // Change the selected date
  void _changeDate(DateTime newDate) {
    // Don't allow future dates
    if (newDate.isAfter(DateTime.now())) {
      newDate = DateTime.now();
    }
    
    setState(() {
      _selectedDate = DateTime(newDate.year, newDate.month, newDate.day);
      _isHistoryMode = !_isSameDay(_selectedDate, DateTime.now());
      _isLoading = true;
    });
    
    _fetchHealthData();
  }
  
  // Reset to today
  void _resetToToday() {
    final today = DateTime.now();
    setState(() {
      _selectedDate = DateTime(today.year, today.month, today.day);
      _isHistoryMode = false;
      _isLoading = true;
    });
    
    _fetchHealthData();
  }

  Future<void> _fetchHealthData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Get permissions
      final types = [
        HealthDataType.STEPS,
      ];
      
      final permissions = types.map((e) => HealthDataAccess.READ).toList();
      final requested = await _health.requestAuthorization(types, permissions: permissions);
      
      if (requested) {
        await _fetchStepsForDate(_selectedDate);
        await _fetchWeeklySteps(_selectedDate);
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Permission denied for Health data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error accessing Health data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _fetchStepsForDate(DateTime date) async {
    try {
      final midnight = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      // Clear loading state first
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      // Request authorization first with even broader permissions for better data access
      final types = [
        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.WORKOUT,
        HealthDataType.MOVE_MINUTES,
      ];
      final permissions = types.map((e) => HealthDataAccess.READ).toList();
      
      // First revoke and re-request permissions to ensure we have fresh access
      try {
        await _health.revokePermissions();
      } catch (e) {
        print('Error revoking permissions: ${e.toString()}');
      }
      
      final authorized = await _health.requestAuthorization(types, permissions: permissions);
      
      if (!authorized) {
        setState(() {
          _errorMessage = 'Permission denied for Health data';
          _isLoading = false;
        });
        return;
      }
      
      print('📊 FETCHING STEPS FOR ${DateFormat('yyyy-MM-dd').format(date)}');
      
      // APPROACH 1: Hourly granular fetch (most accurate)
      try {
        print('Trying hourly granular approach for steps');
        int hourlyTotal = 0;
        
        // Fetch data in hourly chunks for maximum accuracy
        for (int hour = 0; hour < 24; hour++) {
          final hourStart = DateTime(date.year, date.month, date.day, hour);
          final hourEnd = DateTime(date.year, date.month, date.day, hour, 59, 59);
          
          final hourlySteps = await _health.getHealthDataFromTypes(
            hourStart, 
            hourEnd, 
            [HealthDataType.STEPS]
          );
          
          int thisHourSteps = 0;
          for (final dataPoint in hourlySteps) {
            final steps = (dataPoint.value as NumericHealthValue).numericValue.toInt();
            thisHourSteps += steps;
          }
          
          if (thisHourSteps > 0) {
            print('Hour $hour: $thisHourSteps steps');
            hourlyTotal += thisHourSteps;
          }
        }
        
        if (hourlyTotal > 0) {
          print('Hourly approach successful, total: $hourlyTotal steps');
          print('📱 STEPS: Using exact step count from Apple Health: $hourlyTotal');
          
          setState(() {
            _currentSteps = hourlyTotal;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('Error with hourly steps approach: $e');
      }
      
      // APPROACH 2: Direct method with statistics query
      try {
        print('Trying Statistics Query approach - most accurate matching Apple Health app');
        final healthSteps = await _health.getHealthDataFromTypes(
          midnight,
          endOfDay,
          [HealthDataType.STEPS]
        );
        
        print('📊 Direct Apple Health fetch: ${healthSteps.length} data points found');
        
        // Calculate total as shown exactly in Health app
        int totalSteps = 0;
        Map<String, int> sourceBreakdown = {};
        
        for (final dataPoint in healthSteps) {
          final stepValue = (dataPoint.value as NumericHealthValue).numericValue.toInt();
          final source = dataPoint.sourceName;
          print('📊 Step data: $stepValue steps from $source at ${dataPoint.dateFrom}');
          
          // Track steps by source for debugging
          if (sourceBreakdown.containsKey(source)) {
            sourceBreakdown[source] = (sourceBreakdown[source] ?? 0) + stepValue;
          } else {
            sourceBreakdown[source] = stepValue;
          }
          
          totalSteps += stepValue;
        }
        
        // Log the breakdown by source
        sourceBreakdown.forEach((source, steps) {
          print('📊 Source: $source - Total Steps: $steps');
        });
        
        print('📊 Total steps from all sources: $totalSteps');
        
        if (totalSteps > 0) {
          print('📱 STEPS: Using exact step count from Apple Health: $totalSteps');
          
          setState(() {
            _currentSteps = totalSteps;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('Error with direct fetch: ${e.toString()}');
      }
      
      // APPROACH 3: Try getTotalStepsInInterval with force refresh and higher limit
      try {
        print('Trying getTotalStepsInInterval with higher limit');
        // Force a higher limit to ensure we get all the data
        final stepsData = await _health.getTotalStepsInInterval(
          midnight, 
          endOfDay
        );
        
        if (stepsData != null && stepsData > 0) {
          print('getTotalStepsInInterval returned $stepsData steps');
          print('📊 Total steps from getTotalStepsInInterval: ${stepsData ?? 0}');
          print('📱 STEPS: Using exact step count from Apple Health: $stepsData');
          
          setState(() {
            _currentSteps = stepsData;
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('Error with getTotalStepsInInterval: ${e.toString()}');
      }
      
      // If we got here and couldn't get any steps, set an error
      setState(() {
        _errorMessage = 'Could not retrieve steps data from Apple Health';
        _isLoading = false;
      });
      
    } catch (e) {
      print('Step fetching critical error: ${e.toString()}');
      setState(() {
        _errorMessage = 'Error accessing Health services: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _fetchWeeklySteps(DateTime selectedDate) async {
    try {
      final weeklyData = <Map<String, dynamic>>[];
      
      // Fetch data for the week around the selected date (3 days before and 3 days after)
      for (int i = -3; i <= 3; i++) {
        final date = DateTime(selectedDate.year, selectedDate.month, selectedDate.day).add(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);
        
        // Use the most reliable method first
        int daySteps = 0;
        print('Fetching weekly data for ${DateFormat('yyyy-MM-dd').format(date)}');
        
        try {
          // First try the direct and most reliable method
          final stepsData = await _health.getTotalStepsInInterval(dayStart, dayEnd);
          if (stepsData != null && stepsData > 0) {
            daySteps = stepsData;
            print('Weekly point direct method: ${DateFormat('yyyy-MM-dd').format(date)} = $daySteps steps');
          }
        } catch (e) {
          print('Error getting direct total steps for $date: $e');
        }
        
        // If direct method fails, use the more detailed method
        if (daySteps == 0) {
          try {
            print('Using detailed method for ${DateFormat('yyyy-MM-dd').format(date)}');
            final steps = await _health.getHealthDataFromTypes(
              dayStart, 
              dayEnd, 
              [HealthDataType.STEPS]
            );
            
            if (steps.isNotEmpty) {
              for (final step in steps) {
                daySteps += (step.value as NumericHealthValue).numericValue.toInt();
              }
              print('Weekly point detailed method: ${DateFormat('yyyy-MM-dd').format(date)} = $daySteps steps');
            }
          } catch (e) {
            print('Error with detailed method for $date: $e');
          }
        }
        
        // If we still don't have data, try hourly approach for more recent dates (within last week)
        if (daySteps == 0 && date.isAfter(DateTime.now().subtract(const Duration(days: 7)))) {
          try {
            print('Using hourly method for ${DateFormat('yyyy-MM-dd').format(date)}');
            // Get steps hour by hour
            for (int hour = 0; hour <= 23; hour++) {
              final hourStart = DateTime(date.year, date.month, date.day, hour);
              final hourEnd = hour < 23 
                  ? DateTime(date.year, date.month, date.day, hour + 1).subtract(const Duration(seconds: 1))
                  : dayEnd;
              
              if (hourEnd.isAfter(DateTime.now())) {
                break; // Don't try to fetch future data
              }
              
              final hourlySteps = await _health.getTotalStepsInInterval(hourStart, hourEnd);
              if (hourlySteps != null) {
                daySteps += hourlySteps;
              }
            }
            print('Weekly point hourly method: ${DateFormat('yyyy-MM-dd').format(date)} = $daySteps steps');
          } catch (e) {
            print('Error with hourly method for $date: $e');
          }
        }
        
        // Create weekday name
        final weekday = DateFormat('E').format(date); // Mon, Tue, etc.
        
        weeklyData.add({
          'day': weekday,
          'steps': daySteps,
          'date': date,
        });
      }
      
      setState(() {
        _weeklySteps.clear();
        _weeklySteps.addAll(weeklyData);
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching weekly steps: ${e.toString()}');
      setState(() {
        _errorMessage = 'Error fetching weekly steps: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isHistoryMode 
            ? 'Steps (${DateFormat('MMM d').format(_selectedDate)})' 
            : 'Daily Steps',
        icon: AppAssets.iconCalendar,
        onIconPressed: _showDatePickerOverlay,
        showBackButton: true,
      ),
      body: Stack(
        children: [
          _isLoading 
            ? _buildLoadingState() 
            : _errorMessage.isNotEmpty 
              ? _buildErrorState() 
              : _buildStepsContent(),
          
          // Date picker overlay
          if (_showDatePicker)
            _buildDatePickerOverlay(),
        ],
      ),
    );
  }
  
  // Build the date picker overlay
  Widget _buildDatePickerOverlay() {
    return GestureDetector(
      onTap: _hideDatePickerOverlay, // Hide when tapping outside the panel
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {}, // Prevent taps inside the panel from closing it
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                
                // Date picker from easy_date_timeline package or CalendarDatePicker
                CalendarDatePicker(
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)), // 2 years ago
                  lastDate: DateTime.now(),
                  onDateChanged: (newDate) {
                    _changeDate(newDate);
                    _hideDatePickerOverlay();
                  },
                ),
                
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Back to today button
                    ElevatedButton.icon(
                      onPressed: () {
                        _resetToToday();
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
                      child: Text(_isHistoryMode ? 'View History Mode' : 'View Today'),
                    ),
                  ],
                ),
              ],
            ),
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
          CircularProgressIndicator(
            color: AppColors.steps,
          ),
          const SizedBox(height: 16),
          Text(
            'Loading health data...',
            style: TextStyle(
              color: AppColors.steps,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not access health data',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchHealthData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Today's step progress card with fade-in animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: _buildStepProgressCard(),
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.s32),
          
          // Animated section title
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.steps.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insights,
                          size: 18,
                          color: AppColors.steps,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Weekly Overview',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.steps,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.s16),
          
          // Weekly chart with fade-in animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: _buildWeeklyChart(),
                ),
              );
            },
          ),
          const SizedBox(height: AppDimensions.s32),
          
          // Stats and achievements with fade-in animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 700),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: _buildStatsGrid(),
                ),
              );
            },
          ),
          
          const SizedBox(height: AppDimensions.s32),
          
          // Tips/motivation section with fade-in animation
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: _buildMotivationCard(),
                ),
              );
            },
          ),
          
          const SizedBox(height: AppDimensions.s16),
        ],
      ),
    );
  }

  Widget _buildStepProgressCard() {
    final progress = _currentSteps / _stepsGoal;
    final remaining = _stepsGoal - _currentSteps;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardTheme.color ?? Colors.white,
            AppColors.steps.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.steps.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Step counter section
          Padding(
            padding: const EdgeInsets.all(AppDimensions.s20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.directions_walk,
                              size: 16,
                              color: AppColors.steps,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isHistoryMode 
                                ? 'Steps for ${DateFormat('MMM d').format(_selectedDate)}' 
                                : 'Today\'s Steps',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.s8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            TweenAnimationBuilder<int>(
                              tween: IntTween(begin: 0, end: _currentSteps),
                              duration: const Duration(seconds: 1),
                              builder: (context, value, child) {
                                return Text(
                                  '$value',
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.steps,
                                  ),
                                );
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                ' / $_stepsGoal',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.steps.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.steps.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'Exact count from Apple Health',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: AppColors.steps,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.steps.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _walkingAnimationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                0,
                                2 * math.sin(_walkingAnimationController.value * 2 * math.pi),
                              ),
                              child: FaIcon(
                                AppAssets.iconSteps,
                                size: AppDimensions.iconLarge,
                                color: AppColors.steps,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.s24),
                
                // Circular progress
                SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Circular progress indicator
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: progress.toDouble()),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return AnimatedCircularProgress(
                            value: value,
                            color: AppColors.steps,
                            size: 200,
                            strokeWidth: 16,
                          );
                        }
                      ),
                      
                      // Achievement milestone indicators
                      if (_currentSteps > 0)
                        ...List.generate(4, (index) {
                          final milestone = (_stepsGoal * 0.25) * (index + 1);
                          final isReached = _currentSteps >= milestone;
                          final angle = (index * (math.pi / 2)) - (math.pi / 4);
                          
                          return Positioned(
                            left: 100 + (75 * math.cos(angle)),
                            top: 100 + (75 * math.sin(angle)),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: isReached ? 1.0 : 0.5),
                              duration: const Duration(milliseconds: 500),
                              builder: (context, value, child) {
                                return AnimatedOpacity(
                                  opacity: isReached ? 1.0 : 0.4,
                                  duration: const Duration(milliseconds: 300),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isReached ? 
                                        Colors.white : 
                                        Colors.white.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isReached ? 
                                          AppColors.steps : 
                                          AppColors.steps.withOpacity(0.3),
                                        width: 2,
                                      ),
                                      boxShadow: isReached ? [
                                        BoxShadow(
                                          color: AppColors.steps.withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ] : null,
                                    ),
                                    child: Text(
                                      '${(((index + 1) * 25)).toInt()}%',
                                      style: TextStyle(
                                        color: isReached ? 
                                          AppColors.steps : 
                                          AppColors.steps.withOpacity(0.5),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }),
                      
                      // Separate percentage text with floating animation
                      Positioned(
                        top: 40,
                        child: AnimatedBuilder(
                          animation: _pulseAnimationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, -2 + (_pulseAnimationController.value * 4)),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 0, end: progress.toDouble()),
                                duration: const Duration(milliseconds: 1500),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, child) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.steps.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.speed,
                                          size: 18,
                                          color: AppColors.steps,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${(value * 100).toInt()}%',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.steps,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Central animated walking figure with pulsing effect
                      Positioned.fill(
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _pulseAnimationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_pulseAnimationController.value * 0.1),
                                child: Container(
                                  height: 120,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    color: AppColors.steps.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.steps.withOpacity(0.2),
                                        blurRadius: 10 * _pulseAnimationController.value,
                                        spreadRadius: 5 * _pulseAnimationController.value,
                                      ),
                                    ],
                                  ),
                                  child: Lottie.asset(
                                    AppAssets.lottieSteps,
                                    height: 110,
                                    width: 110,
                                    controller: _walkingAnimationController,
                                    repeat: true,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.directions_walk,
                                        size: 60,
                                        color: AppColors.steps.withOpacity(0.8),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      // Show achievement badge if goal reached
                      if (_currentSteps >= _stepsGoal)
                        Positioned(
                          top: 10,
                          right: 30,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Remaining steps with improved visualization
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: remaining > 0 
                        ? AppColors.steps.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(
                      color: remaining > 0 
                          ? AppColors.steps.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        remaining > 0 ? Icons.timer : Icons.check_circle,
                        size: 18,
                        color: remaining > 0 ? AppColors.steps : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        remaining > 0
                            ? '$remaining steps to reach your goal'
                            : 'Goal reached! Great job! 🎉',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: remaining > 0 ? AppColors.steps : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Quick stats bar
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.s16,
              horizontal: AppDimensions.s20,
            ),
            decoration: BoxDecoration(
              color: AppColors.steps.withOpacity(0.08),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppDimensions.radiusLarge),
                bottomRight: Radius.circular(AppDimensions.radiusLarge),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.apple,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Steps data provided by Apple Health',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                // Refresh button specifically for step count
                GestureDetector(
                  onTap: () {
                    // Force refresh Apple Health data
                    setState(() {
                      _isLoading = true;
                    });
                    _fetchStepsForDate(_selectedDate);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.steps.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh,
                          size: 14,
                          color: AppColors.steps,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Refresh Step Count',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.steps,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart() {
    if (_weeklySteps.isEmpty) {
      return const Center(
        child: Text('No weekly data available'),
      );
    }
    
    // Find the maximum step value for scaling
    final maxSteps = _weeklySteps.isNotEmpty 
        ? _weeklySteps.map((day) => day['steps'] as int).reduce((a, b) => a > b ? a : b)
        : 10000;
    
    return Container(
      height: 250,
      padding: const EdgeInsets.all(AppDimensions.s16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardTheme.color ?? Colors.white,
            AppColors.steps.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.steps.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Chart header with improved styling
          Container(
            padding: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.steps.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.bar_chart,
                      size: 18,
                      color: AppColors.steps,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isHistoryMode 
                        ? '7 Days Around ${DateFormat('MMM d').format(_selectedDate)}' 
                        : '7-Day Overview',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.steps.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 14,
                        color: AppColors.steps,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Avg: ${_calculateWeeklyAverage()} steps',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.steps,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppDimensions.s16),
          
          // Chart bars with animation
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weeklySteps.asMap().entries.map((entry) {
                final index = entry.key;
                final day = entry.value;
                final isToday = _isToday(day['date']);
                
                return TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: Duration(milliseconds: 800 + (index * 100)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return _buildAnimatedDayBar(day, maxSteps, isToday, value);
                  }
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: AppDimensions.s12),
          
          // Day labels with improved visibility
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weeklySteps.map((day) {
              final isToday = _isToday(day['date']);
              final isSelectedDay = _isSameDay(day['date'], _selectedDate);
              
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: isSelectedDay ? BoxDecoration(
                  color: AppColors.steps.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ) : null,
                child: Text(
                  day['day'],
                  style: TextStyle(
                    color: isToday
                        ? AppColors.steps
                        : isSelectedDay
                            ? AppColors.steps.withOpacity(0.9)
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: isToday || isSelectedDay ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDayBar(Map<String, dynamic> day, int maxSteps, bool isToday, double animationValue) {
    final steps = day['steps'] as int;
    // Calculate height percentage (max height is the chart height minus some padding)
    final heightPercentage = maxSteps > 0 ? (steps / maxSteps).clamp(0.0, 1.0) : 0.0;
    // Maximum bar height is 100 instead of 120 to avoid overflow
    final barHeight = 100 * heightPercentage * animationValue;
    final isSelectedDay = _isSameDay(day['date'], _selectedDate);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Step count tooltip with improved styling
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: isToday || isSelectedDay
                ? AppColors.steps
                : AppColors.steps.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Text(
            '${(steps / 1000).toStringAsFixed(1)}k',
            style: TextStyle(
              color: isToday || isSelectedDay
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        
        // Bar with improved design
        Container(
          height: barHeight,
          width: 26,
          decoration: BoxDecoration(
            color: isToday || isSelectedDay
                ? AppColors.steps
                : AppColors.steps.withOpacity(0.3),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            boxShadow: [
              if (isToday || isSelectedDay)
                BoxShadow(
                  color: AppColors.steps.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: isToday || isSelectedDay
                  ? [
                      AppColors.steps,
                      AppColors.steps.withOpacity(0.7),
                    ]
                  : [
                      AppColors.steps.withOpacity(0.3),
                      AppColors.steps.withOpacity(0.1),
                    ],
            ),
          ),
          child: steps > _stepsGoal
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 14,
                  ),
                ),
              )
            : null,
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardTheme.color ?? Colors.white,
            AppColors.steps.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.steps.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 18,
                color: AppColors.steps,
              ),
              const SizedBox(width: 8),
              Text(
                'Activity Insights',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Stats grid with animation
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppDimensions.s16,
            crossAxisSpacing: AppDimensions.s16,
            childAspectRatio: 1.5,
            children: [
              _buildEnhancedStatCard(
                title: 'Daily Average',
                value: '${_calculateWeeklyAverage()}',
                unit: 'steps',
                icon: Icons.calendar_view_week,
                color: AppColors.steps,
                percentOfGoal: _calculateWeeklyAverage() / _stepsGoal,
              ),
              _buildEnhancedStatCard(
                title: 'Monthly Total',
                value: '${_calculateMonthlyTotal()}',
                unit: 'steps',
                icon: Icons.calendar_month,
                color: AppColors.steps,
                showBadge: _calculateMonthlyTotal() > 300000,
              ),
              _buildEnhancedStatCard(
                title: 'Best Day',
                value: '${_findBestDay()}',
                unit: 'steps',
                icon: Icons.emoji_events,
                color: Colors.amber,
                showBadge: _findBestDay() > _stepsGoal * 1.5,
              ),
              _buildEnhancedStatCard(
                title: 'Active Days',
                value: '${_countActiveDays()}',
                unit: 'days',
                icon: Icons.local_fire_department,
                color: Colors.orange,
                percentOfGoal: _countActiveDays() / 7,
                showBadge: _countActiveDays() >= 5,
              ),
            ],
          ),
          
          // Achievement section
          if (_findBestDay() > _stepsGoal || _countActiveDays() >= 5)
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 18,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Achievements',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Achievements list
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (_findBestDay() > _stepsGoal)
                        _buildAchievementBadge(
                          'Goal Crusher',
                          Icons.military_tech,
                          Colors.amber,
                        ),
                      if (_countActiveDays() >= 5)
                        _buildAchievementBadge(
                          'Active Week',
                          Icons.local_fire_department,
                          Colors.deepOrange,
                        ),
                      if (_findBestDay() > 15000)
                        _buildAchievementBadge(
                          'Step Master',
                          Icons.directions_run,
                          AppColors.steps,
                        ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    double? percentOfGoal,
    bool showBadge = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(AppDimensions.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title and icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 14,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                // Value with animation
                Expanded(
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: double.parse(value)),
                      duration: const Duration(milliseconds: 1200),
                      curve: Curves.easeOutQuart,
                      builder: (context, value, child) {
                        return RichText(
                          text: TextSpan(
                            text: '${value.toInt()}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                            children: [
                              TextSpan(
                                text: ' $unit',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // Progress indicator if percentOfGoal is provided
                if (percentOfGoal != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        height: 4,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: percentOfGoal.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(percentOfGoal * 100).toInt()}% of goal',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Badge for achievements
          if (showBadge)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(AppDimensions.radiusMedium),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildAchievementBadge(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateWeeklyAverage() {
    if (_weeklySteps.isEmpty) return 0;
    
    final totalSteps = _weeklySteps.fold<int>(
      0,
      (previousValue, day) => previousValue + (day['steps'] as int),
    );
    return (totalSteps / _weeklySteps.length).round();
  }
  
  int _calculateMonthlyTotal() {
    if (_weeklySteps.isEmpty) return 0;
    // For demo, just multiply weekly by 4
    return _calculateWeeklyAverage() * 30;
  }
  
  int _findBestDay() {
    if (_weeklySteps.isEmpty) return 0;
    
    return _weeklySteps
        .map((day) => day['steps'] as int)
        .reduce((a, b) => a > b ? a : b);
  }
  
  int _countActiveDays() {
    if (_weeklySteps.isEmpty) return 0;
    
    return _weeklySteps
        .where((day) => (day['steps'] as int) > 5000)
        .length;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Widget _buildMotivationCard() {
    // Different tips based on current progress
    final bool goalReached = _currentSteps >= _stepsGoal;
    final bool closeToGoal = _currentSteps >= _stepsGoal * 0.8;
    final bool lowActivity = _currentSteps < _stepsGoal * 0.3;
    
    String tip;
    IconData icon;
    Color color;
    
    if (goalReached) {
      tip = "Amazing! You've hit your daily goal. Keep up the great work!";
      icon = Icons.celebration;
      color = Colors.green;
    } else if (closeToGoal) {
      tip = "You're so close to your goal! Just ${_stepsGoal - _currentSteps} more steps to go!";
      icon = Icons.directions_run;
      color = Colors.orange;
    } else if (lowActivity) {
      tip = "Try to take a quick walk break. Even 5-10 minutes can help you reach your goal!";
      icon = Icons.directions_walk;
      color = AppColors.steps;
    } else {
      tip = "Remember: 10,000 steps per day can significantly improve your health!";
      icon = Icons.favorite;
      color = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Tip",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 