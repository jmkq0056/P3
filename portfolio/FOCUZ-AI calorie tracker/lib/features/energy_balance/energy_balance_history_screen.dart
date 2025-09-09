import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:health/health.dart';
import '../../core/constants.dart';
import '../../models/energy_balance_record.dart';
import '../../models/health_data.dart';
import '../../models/meal_data.dart';
import '../../services/health_service.dart';
import '../../services/meal_service.dart';
import '../../services/training_service.dart' as training_service;
import '../../widgets/custom_app_bar.dart';
import '../dashboard/dashboard_screen.dart'; // Import for AppState
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EnergyBalanceHistoryScreen extends StatefulWidget {
  const EnergyBalanceHistoryScreen({super.key});

  @override
  State<EnergyBalanceHistoryScreen> createState() => _EnergyBalanceHistoryScreenState();
}

class _EnergyBalanceHistoryScreenState extends State<EnergyBalanceHistoryScreen> {
  final HealthService _healthService = HealthService();
  final MealService _mealService = MealService();
  final training_service.TrainingService _trainingService = training_service.TrainingService();
  final HealthFactory _health = HealthFactory(useHealthConnectIfAvailable: false);
  final AppState _appState = AppState();
  
  bool _isLoading = true;
  String? _errorMessage;
  List<DailyEnergyRecord> _energyRecords = [];
  final int _daysToShow = 14;  // Show two weeks of history
  static const String _energyRecordsKey = 'energy_balance_records';

  @override
  void initState() {
    super.initState();
    _initializeServices();
    // Add listener to AppState to refresh data when anything changes
    _appState.addListener(_onAppStateChanged);
  }
  
  @override
  void dispose() {
    // Remove listener when widget is disposed
    _appState.removeListener(_onAppStateChanged);
    super.dispose();
  }
  
  // Callback for when AppState changes (e.g., when a training is added/edited/deleted)
  void _onAppStateChanged() {
    debugPrint('EnergyBalance: App state changed, refreshing energy history...');
    _loadEnergyHistory();
  }
  
  Future<void> _initializeServices() async {
    try {
      // Initialize MealService first
      await _mealService.init();
      
      // Initialize TrainingService to ensure training data is available
      await _trainingService.init();
      
      // Health service initialization
      await _healthService.init();
      
      // Load energy records from SharedPreferences
      await _loadStoredRecords();
      
      // Load energy history if needed
      await _loadEnergyHistory();
    } catch (e) {
      debugPrint('Error during initialization: $e');
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load energy history: $e';
      });
    }
  }
  
  Future<void> _loadStoredRecords() async {
    final currentDate = DateTime.now();
    final List<DailyEnergyRecord> records = [];
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedData = prefs.getString(_energyRecordsKey);
      
      if (storedData != null && storedData.isNotEmpty) {
        final List<dynamic> recordsJson = jsonDecode(storedData);
        
        for (var json in recordsJson) {
          final record = EnergyBalanceRecord.fromJson(json);
          
          // Filter to get only records for the last _daysToShow days
          final recordDate = record.date;
          final difference = currentDate.difference(recordDate).inDays;
          
          if (difference < _daysToShow) {
            records.add(record.toDailyRecord());
          }
        }
        
        // Update UI
        if (records.isNotEmpty) {
          setState(() {
            _energyRecords = records;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading stored records: $e');
      // Clear corrupted data if there's an error
      await _clearCorruptedEnergyData();
      // Make sure the UI shows loading state
      setState(() {
        _isLoading = true;
      });
    }
  }
  
  // Clear corrupted energy data
  Future<void> _clearCorruptedEnergyData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_energyRecordsKey);
      debugPrint('Cleared corrupted energy balance data');
    } catch (e) {
      debugPrint('Error clearing energy balance data: $e');
    }
  }

  Future<void> _loadEnergyHistory() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Reinitialize services to get fresh data
      await _trainingService.init();
      
      final currentDate = DateTime.now();
      // We'll create new records for all days to ensure we have the latest data
      final List<DailyEnergyRecord> records = [];
      // Keep track of dates we've processed
      final Set<String> processedDates = {};
      
      // Load records for the past X days
      for (int i = 0; i < _daysToShow; i++) {
        final date = DateTime(currentDate.year, currentDate.month, currentDate.day).subtract(Duration(days: i));
        final dateKey = _formatDateKey(date);
        
        // Skip if we've already processed this date
        if (processedDates.contains(dateKey)) continue;
        
        try {
          // Always load fresh data for each date
          final record = await _loadEnergyRecordForDate(date);
          if (record != null) {
            records.add(record);
            processedDates.add(dateKey);
            
            // Save to SharedPreferences
            await _saveEnergyRecord(record);
          }
        } catch (e) {
          debugPrint('Error loading record for date ${date.toString()}: $e');
          // Continue with other dates
        }
      }
      
      // Sort records by date
      records.sort((a, b) => b.date.compareTo(a.date));
      
      if (mounted) {
        setState(() {
          _energyRecords = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading energy history: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load energy data: $e';
        });
      }
    }
  }
  
  // Helper method to save energy record to SharedPreferences
  Future<void> _saveEnergyRecord(DailyEnergyRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordData = EnergyBalanceRecord.fromDailyRecord(record);
      
      // Get existing records
      String? storedData = prefs.getString(_energyRecordsKey);
      List<dynamic> records = [];
      
      if (storedData != null && storedData.isNotEmpty) {
        records = jsonDecode(storedData);
      }
      
      // Convert to a list of JSON objects
      List<Map<String, dynamic>> recordsList = records.cast<Map<String, dynamic>>();
      
      // Remove any existing record for this date
      recordsList.removeWhere((r) => 
        DateTime.parse(r['date']).year == record.date.year && 
        DateTime.parse(r['date']).month == record.date.month && 
        DateTime.parse(r['date']).day == record.date.day
      );
      
      // Add new record
      recordsList.add(recordData.toJson());
      
      // Save back to SharedPreferences
      await prefs.setString(_energyRecordsKey, jsonEncode(recordsList));
    } catch (e) {
      debugPrint('Error saving energy record: $e');
    }
  }

  Future<DailyEnergyRecord?> _loadEnergyRecordForDate(DateTime date) async {
    try {
      // Get nutrition profile for BMR calculation
      final nutritionProfile = _mealService.getNutritionProfile();
      if (nutritionProfile == null) {
        debugPrint('Nutrition profile is null for date: ${date.toString()}');
        
        // Even without a profile, try to get actual data for the day 
        final caloriesConsumed = _mealService.getTotalCaloriesForDay(date);
        final trainingCalories = _calculateTrainingCaloriesForDay(date);
        int walkingCalories = 0;
        try {
          walkingCalories = await _calculateWalkingCaloriesForDay(date);
        } catch (e) {
          debugPrint('Error calculating walking calories: $e');
        }
        
        // Use a reasonable default BMR of 2000 calories
        const defaultBmr = 2000;
        
        // Calculate deficit based on actual data
        final calorieSurplusDeficit = defaultBmr - caloriesConsumed + walkingCalories + trainingCalories;
        
        final defaultRecord = DailyEnergyRecord(
          date: date,
          caloriesGoal: defaultBmr,
          caloriesConsumed: caloriesConsumed,
          walkingCalories: walkingCalories,
          trainingCalories: trainingCalories, 
          calorieSurplusDeficit: calorieSurplusDeficit,
        );
        
        return defaultRecord;
      }
      
      // Get calories goal (BMR)
      final caloriesGoal = nutritionProfile.calculateTargetCalories();
      
      // Get consumed calories for the day - actual data
      final caloriesConsumed = _mealService.getTotalCaloriesForDay(date);
      
      // Get walking calories burned (safe call) - actual data
      int walkingCalories = 0;
      try {
        walkingCalories = await _calculateWalkingCaloriesForDay(date);
      } catch (e) {
        debugPrint('Error calculating walking calories: $e');
      }
      
      // Get training calories - actual data
      final trainingCalories = _calculateTrainingCaloriesForDay(date);
      
      // Calculate surplus/deficit (safely)
      int calorieSurplusDeficit;
      try {
        // Force manual calculation to ensure consistency
        calorieSurplusDeficit = caloriesGoal - caloriesConsumed + walkingCalories + trainingCalories;
      } catch (e) {
        debugPrint('Error calculating surplus/deficit: $e');
        // Calculate manually as fallback
        calorieSurplusDeficit = caloriesGoal - caloriesConsumed + walkingCalories + trainingCalories;
      }
      
      // Create a record for this day with actual data
      return DailyEnergyRecord(
        date: date,
        caloriesGoal: caloriesGoal,
        caloriesConsumed: caloriesConsumed,
        walkingCalories: walkingCalories,
        trainingCalories: trainingCalories,
        calorieSurplusDeficit: calorieSurplusDeficit,
      );
    } catch (e) {
      debugPrint('Error creating record for ${date.toString()}: $e');
      
      // Try to create a fallback record with any data we can get
      try {
        final caloriesConsumed = _mealService.getTotalCaloriesForDay(date);
        final trainingCalories = _calculateTrainingCaloriesForDay(date);
        
        // Use conservative defaults
        return DailyEnergyRecord(
          date: date,
          caloriesGoal: 2000, // Default fallback goal
          caloriesConsumed: caloriesConsumed,
          walkingCalories: 0,
          trainingCalories: trainingCalories,
          calorieSurplusDeficit: 2000 - caloriesConsumed + trainingCalories,
        );
      } catch (e2) {
        // If everything fails, use empty data
        return DailyEnergyRecord(
          date: date,
          caloriesGoal: 2000,
          caloriesConsumed: 0,
          walkingCalories: 0,
          trainingCalories: 0,
          calorieSurplusDeficit: 0,
        );
      }
    }
  }
  
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  int _calculateTrainingCaloriesForDay(DateTime date) {
    // Get the trainings for the specific day
    final trainings = _trainingService.getTrainingsForDay(date);
    int totalCalories = 0;
    
    for (final training in trainings) {
      totalCalories += training.calories.toInt();
    }
    
    debugPrint('Energy Balance: Found ${trainings.length} trainings for ${DateFormat('yyyy-MM-dd').format(date)}, total calories: $totalCalories');
    return totalCalories;
  }

  Future<int> _calculateWalkingCaloriesForDay(DateTime date) async {
    final nutritionProfile = _mealService.getNutritionProfile();
    if (nutritionProfile == null) {
      debugPrint('Nutrition profile is null when calculating walking calories');
      return 0;
    }
    
    // FIRST TRY: Get Active Energy Burned directly from Apple Health
    try {
      final activeEnergyBurned = await _healthService.getActiveEnergyBurnedForDay(date);
      if (activeEnergyBurned > 0) {
        debugPrint('📱 ENERGY BALANCE: Using Apple Health Active Energy data directly: $activeEnergyBurned calories');
        return activeEnergyBurned;  // Return the data from Apple Health
      } else {
        debugPrint('⚠️ ENERGY BALANCE: No Active Energy data available in Apple Health, falling back to custom calculation');
      }
    } catch (e) {
      debugPrint('Error getting Active Energy from Apple Health: $e');
      debugPrint('⚠️ ENERGY BALANCE: Falling back to custom step-based calculation');
    }
    
    // FALLBACK: Get latest weight
    final latestWeight = _healthService.getLatestWeightEntry();
    final weightKg = latestWeight?.weight ?? nutritionProfile.weight;
    
    // Get profile height and gender
    final heightCm = nutritionProfile.heightCm;
    final gender = nutritionProfile.gender;
    
    // Get user stride length if set
    final userStrideLength = nutritionProfile.strideLengthMeters;
    
    // Get steps for the selected day from HealthKit
    final steps = await _getStepsForDay(date);
    
    if (steps > 0) {
      return _healthService.calculateWalkingCalories(
        steps: steps,
        weightKg: weightKg,
        heightCm: heightCm,
        gender: gender,
        userProvidedStrideLength: userStrideLength,
      );
    }
    
    return 0;
  }
  
  // Fetch steps for a specific day from HealthKit
  Future<int> _getStepsForDay(DateTime date) async {
    try {
      final midnight = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final types = [HealthDataType.STEPS];
      final permissions = types.map((e) => HealthDataAccess.READ).toList();
      final authorized = await _health.requestAuthorization(types, permissions: permissions);
      
      if (authorized) {
        // Method 1: Hourly approach (most reliable)
        int hourlyTotal = 0;
        
        for (int hour = 0; hour < 24; hour++) {
          final hourStart = DateTime(date.year, date.month, date.day, hour);
          final hourEnd = DateTime(date.year, date.month, date.day, hour, 59, 59);
          
          try {
            final hourlySteps = await _health.getTotalStepsInInterval(hourStart, hourEnd);
            if (hourlySteps != null) {
              hourlyTotal += hourlySteps;
            }
          } catch (e) {
            debugPrint('Error getting hourly steps: $e');
          }
        }
        
        if (hourlyTotal > 0) {
          debugPrint('📱 ENERGY BALANCE: Using exact step count from Apple Health: $hourlyTotal');
          return hourlyTotal;
        }
        
        // Method 2: Try direct method with higher limit
        try {
          final stepsData = await _health.getTotalStepsInInterval(
            midnight, 
            endOfDay
          );
          
          if (stepsData != null && stepsData > 0) {
            debugPrint('Energy Balance - Direct method: $stepsData steps');
            debugPrint('📱 ENERGY BALANCE: Using exact step count from Apple Health: $stepsData');
            return stepsData;
          }
        } catch (e) {
          debugPrint('Error getting total steps: $e');
        }
        
        // Method 3: Fallback to detailed method
        final steps = await _health.getHealthDataFromTypes(
          midnight, 
          endOfDay, 
          [HealthDataType.STEPS]
        );
        
        if (steps.isNotEmpty) {
          int totalSteps = 0;
          Map<String, int> sourceBreakdown = {};
          
          for (final step in steps) {
            final stepValue = (step.value as NumericHealthValue).numericValue.toInt();
            final source = step.sourceName;
            
            // Track steps by source for debugging
            if (sourceBreakdown.containsKey(source)) {
              sourceBreakdown[source] = (sourceBreakdown[source] ?? 0) + stepValue;
            } else {
              sourceBreakdown[source] = stepValue;
            }
            
            totalSteps += stepValue;
          }
          
          // Log breakdown by source
          sourceBreakdown.forEach((source, count) {
            debugPrint('Energy Balance - Source: $source, Steps: $count');
          });
          
          debugPrint('Energy Balance - Total steps: $totalSteps');
          debugPrint('📱 ENERGY BALANCE: Using exact step count from Apple Health: $totalSteps');
          return totalSteps;
        }
      }
    } catch (e) {
      debugPrint('Error fetching steps: $e');
    }
    
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Energy Balance History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEnergyHistory,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null 
          ? _buildErrorView()
          : _energyRecords.isEmpty
            ? _buildEmptyView()
            : _buildHistoryContent(),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
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
              _errorMessage ?? 'An error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              onPressed: _loadEnergyHistory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.chartBar,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No energy balance records found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We\'ll track your energy balance as you log meals and activities',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const FaIcon(FontAwesomeIcons.refresh),
              label: const Text('Refresh'),
              onPressed: _loadEnergyHistory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryContent() {
    if (_energyRecords.isEmpty) {
      return const Center(
        child: Text('No energy balance records found.'),
      );
    }
    
    return Column(
      children: [
        // Graph section
        Container(
          height: 200,
          padding: const EdgeInsets.all(AppDimensions.s16),
          child: _buildEnergyBalanceChart(),
        ),
        
        // List of records
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.s16),
            itemCount: _energyRecords.length,
            itemBuilder: (context, index) {
              final record = _energyRecords[index];
              return _buildEnergyBalanceCard(record);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildEnergyBalanceChart() {
    // Sort records by date for the chart
    final chartRecords = List.of(_energyRecords)
      ..sort((a, b) => a.date.compareTo(b.date)); // Sort from old to new for better viewing
    
    // Use only the last 7 days (most recent data)
    final recentRecords = chartRecords.length > 7 
      ? chartRecords.sublist(chartRecords.length - 7) 
      : chartRecords;
    
    if (recentRecords.isEmpty) {
      return const Center(child: Text('No data available for chart'));
    }

    // Find the maximum absolute value for scaling
    final maxValue = recentRecords.fold<double>(
      1000,
      (max, record) => math.max(max, record.calorieSurplusDeficit.abs().toDouble()),
    );

    return Column(
      children: [
        // Chart legend with more detail
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                color: Colors.green,
              ),
              const SizedBox(width: 4),
              const Text('Deficit (Weight Loss)', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              Container(
                width: 12,
                height: 12,
                color: Colors.orange,
              ),
              const SizedBox(width: 4),
              const Text('Surplus (Weight Gain)', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // Simple bar chart
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: recentRecords.map((record) {
              final isDeficit = record.calorieSurplusDeficit > 0;
              // Safety check - use absolute value and cap at max for visualization
              final value = math.min(record.calorieSurplusDeficit.abs().toDouble(), maxValue);
              // Make sure at least tiny bars show for small values
              final height = value > 0 
                ? math.max(5.0, (value / maxValue) * 120) 
                : 5.0; // Minimum height to make bar visible
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Small value indicator
                      Text(
                        '${record.calorieSurplusDeficit.abs()}',
                        style: const TextStyle(fontSize: 8),
                      ),
                      const SizedBox(height: 2),
                      // The bar
                      Container(
                        height: height,
                        color: isDeficit ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(height: 4),
                      // Day label
                      Text(
                        DateFormat('E').format(record.date),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEnergyBalanceCard(DailyEnergyRecord record) {
    // Determine if in surplus or deficit
    final bool isDeficit = record.calorieSurplusDeficit > 0;
    final bool isZero = record.calorieSurplusDeficit == 0;
    
    // Set colors based on deficit/surplus status
    final Color statusColor = isZero 
        ? Colors.blue
        : isDeficit 
            ? Colors.green  // Deficit (good)
            : Colors.orange; // Surplus (warning)
    
    final String statusText = isZero
        ? 'Balanced'
        : isDeficit 
            ? 'Deficit'
            : 'Surplus';
    
    // Format date
    final dateFormat = DateFormat('EEEE, MMM d');
    final isToday = record.date.year == DateTime.now().year && 
                   record.date.month == DateTime.now().month && 
                   record.date.day == DateTime.now().day;
    final dateLabel = isToday ? 'Today' : dateFormat.format(record.date);
            
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.s16),
      elevation: 2,
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
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
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
              ],
            ),
            const SizedBox(height: AppDimensions.s16),
            
            // Calorie details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Food intake
                Expanded(
                  child: _buildEnergyColumn(
                    'Food',
                    record.caloriesConsumed,
                    FontAwesomeIcons.utensils,
                    AppColors.calories,
                  ),
                ),
                
                // BMR
                Expanded(
                  child: _buildEnergyColumn(
                    'BMR',
                    record.caloriesGoal,
                    FontAwesomeIcons.fire,
                    Colors.orange,
                  ),
                ),
                
                // Walking 
                Expanded(
                  child: _buildEnergyColumn(
                    'Walking',
                    record.walkingCalories,
                    FontAwesomeIcons.personWalking, 
                    AppColors.steps,
                  ),
                ),
                
                // Training
                Expanded(
                  child: _buildEnergyColumn(
                    'Training',
                    record.trainingCalories,
                    FontAwesomeIcons.dumbbell, 
                    AppColors.accent,
                  ),
                ),
                
                // Deficit/surplus
                Expanded(
                  child: _buildEnergyColumn(
                    statusText,
                    record.calorieSurplusDeficit.abs(),
                    isDeficit ? FontAwesomeIcons.angleDown : FontAwesomeIcons.angleUp,
                    statusColor,
                  ),
                ),
              ],
            ),
            
            // Add a divider and summary
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Net calories section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: FaIcon(
                        isDeficit ? FontAwesomeIcons.fire : FontAwesomeIcons.pizzaSlice,
                        color: statusColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDeficit ? 'Calorie Deficit' : 'Calorie Surplus',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          isDeficit 
                            ? 'Burned ${record.calorieSurplusDeficit} more calories than consumed'
                            : 'Consumed ${record.calorieSurplusDeficit.abs()} more calories than burned',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Weight impact - rough estimate
                
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnergyColumn(String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: FaIcon(
            icon,
            color: color,
            size: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
} 