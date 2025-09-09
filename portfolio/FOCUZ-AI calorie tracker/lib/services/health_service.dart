import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_data.dart';
import '../models/training.dart';
import 'dart:math' as math;
import 'package:health/health.dart';
import './firestore_service.dart';

class HealthService {
  static const String _weightStorageKey = 'weight_entries';
  static const String _waterStorageKey = 'water_entries';
  static const String _sleepStorageKey = 'sleep_entries';
  
  // In-memory cache for entries
  List<WeightEntry> _weightEntries = [];
  List<WaterEntry> _waterEntries = [];
  List<SleepEntry> _sleepEntries = [];
  List<Training> _trainingEntries = [];
  
  // Firestore service
  final FirestoreService _firestoreService = FirestoreService();
  
  // Flag to track if data should be loaded from local or Firestore
  bool _useFirestore = false;
  
  // Initialize
  Future<void> init() async {
    // Check if migration is completed
    final prefs = await SharedPreferences.getInstance();
    final migrationKey = 'firestore_migration_completed_${_firestoreService.userId}';
    _useFirestore = prefs.getBool(migrationKey) ?? false;
    
    // Initialize Firestore service
    await _firestoreService.init();
    
    // If migration is not complete, use SharedPreferences
    if (!_useFirestore) {
      await _loadFromSharedPreferences();
    } else {
      await _loadFromFirestore();
    }
  }
  
  // Load from SharedPreferences
  Future<void> _loadFromSharedPreferences() async {
    await _loadWeightEntries();
    await _loadWaterEntries();
    await _loadSleepEntries();
    await _loadTrainingEntries();
  }
  
  // Load from Firestore
  Future<void> _loadFromFirestore() async {
    await _loadWeightEntriesFromFirestore();
    await _loadWaterEntriesFromFirestore();
    await _loadSleepEntriesFromFirestore();
  }
  
  // --- Weight methods with Firestore ---
  
  Future<void> _loadWeightEntriesFromFirestore() async {
    try {
      _weightEntries = await _firestoreService.getAllWeightEntries();
      debugPrint('Loaded ${_weightEntries.length} weight entries from Firestore');
    } catch (e) {
      debugPrint('Error loading weight entries from Firestore: $e');
      _weightEntries = [];
    }
  }
  
  Future<void> _loadWeightEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? entryData = prefs.getString(_weightStorageKey);
      
      if (entryData != null && entryData.isNotEmpty) {
        final List<dynamic> entriesJson = jsonDecode(entryData);
        _weightEntries = entriesJson.map((json) => WeightEntry.fromJson(json)).toList();
        debugPrint('Loaded ${_weightEntries.length} weight entries from SharedPreferences');
      } else {
        _weightEntries = [];
        debugPrint('No weight entries found in storage');
      }
    } catch (e) {
      debugPrint('Error loading weight entries: $e');
      _weightEntries = [];
    }
  }
  
  Future<void> _saveWeightEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = _weightEntries.map((entry) => entry.toJson()).toList();
      final encoded = jsonEncode(entriesJson);
      await prefs.setString(_weightStorageKey, encoded);
      debugPrint('Saved ${_weightEntries.length} weight entries to SharedPreferences');
    } catch (e) {
      debugPrint('Error saving weight entries: $e');
    }
  }
  
  Future<void> addWeightEntry(WeightEntry entry) async {
    _weightEntries.add(entry);
    
    if (_useFirestore) {
      // Save to Firestore
      await _firestoreService.saveWeightEntry(entry);
      debugPrint('Saved weight entry to Firestore');
    } else {
      // Save to SharedPreferences
      await _saveWeightEntries();
    }
  }
  
  Future<void> deleteWeightEntry(String id) async {
    _weightEntries.removeWhere((entry) => entry.id == id);
    
    if (_useFirestore) {
      // Delete from Firestore
      await _firestoreService.deleteWeightEntry(id);
      debugPrint('Deleted weight entry from Firestore');
    } else {
      // Save to SharedPreferences
      await _saveWeightEntries();
    }
  }
  
  List<WeightEntry> getAllWeightEntries() {
    return List<WeightEntry>.from(_weightEntries);
  }
  
  List<WeightEntry> getWeightEntriesByDateRange(DateTime start, DateTime end) {
    return _weightEntries.where((entry) {
      return entry.date.isAfter(start) && entry.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
  
  WeightEntry? getLatestWeightEntry() {
    if (_weightEntries.isEmpty) return null;
    
    final entries = List<WeightEntry>.from(_weightEntries);
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries.first;
  }
  
  // --- Water methods with Firestore ---
  
  Future<void> _loadWaterEntriesFromFirestore() async {
    try {
      _waterEntries = await _firestoreService.getAllWaterEntries();
      debugPrint('Loaded ${_waterEntries.length} water entries from Firestore');
    } catch (e) {
      debugPrint('Error loading water entries from Firestore: $e');
      _waterEntries = [];
    }
  }
  
  Future<void> _loadWaterEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? entryData = prefs.getString(_waterStorageKey);
      
      if (entryData != null && entryData.isNotEmpty) {
        final List<dynamic> entriesJson = jsonDecode(entryData);
        _waterEntries = entriesJson.map((json) => WaterEntry.fromJson(json)).toList();
        debugPrint('Loaded ${_waterEntries.length} water entries from SharedPreferences');
      } else {
        _waterEntries = [];
        debugPrint('No water entries found in storage');
      }
    } catch (e) {
      debugPrint('Error loading water entries: $e');
      _waterEntries = [];
    }
  }
  
  Future<void> _saveWaterEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = _waterEntries.map((entry) => entry.toJson()).toList();
      final encoded = jsonEncode(entriesJson);
      await prefs.setString(_waterStorageKey, encoded);
      debugPrint('Saved ${_waterEntries.length} water entries to SharedPreferences');
    } catch (e) {
      debugPrint('Error saving water entries: $e');
    }
  }
  
  Future<void> addWaterEntry(WaterEntry entry) async {
    _waterEntries.add(entry);
    
    if (_useFirestore) {
      // Save to Firestore
      await _firestoreService.saveWaterEntry(entry);
      debugPrint('Saved water entry to Firestore');
    } else {
      // Save to SharedPreferences
      await _saveWaterEntries();
    }
  }
  
  Future<void> deleteWaterEntry(String id) async {
    _waterEntries.removeWhere((entry) => entry.id == id);
    
    if (_useFirestore) {
      // Delete from Firestore
      await _firestoreService.deleteWaterEntry(id);
      debugPrint('Deleted water entry from Firestore');
    } else {
      // Save to SharedPreferences
      await _saveWaterEntries();
    }
  }
  
  List<WaterEntry> getAllWaterEntries() {
    return List<WaterEntry>.from(_waterEntries);
  }
  
  List<WaterEntry> getWaterEntriesForDay(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _waterEntries.where((entry) {
      return entry.date.isAfter(start) && entry.date.isBefore(end);
    }).toList();
  }
  
  double getTotalWaterForDay(DateTime date) {
    final entries = getWaterEntriesForDay(date);
    return entries.fold(0, (sum, entry) => sum + entry.amount);
  }
  
  // --- Sleep methods with Firestore ---
  
  Future<void> _loadSleepEntriesFromFirestore() async {
    try {
      _sleepEntries = await _firestoreService.getAllSleepEntries();
      debugPrint('Loaded ${_sleepEntries.length} sleep entries from Firestore');
    } catch (e) {
      debugPrint('Error loading sleep entries from Firestore: $e');
      _sleepEntries = [];
    }
  }
  
  Future<void> _loadSleepEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? entryData = prefs.getString(_sleepStorageKey);
      
      if (entryData != null && entryData.isNotEmpty) {
        final List<dynamic> entriesJson = jsonDecode(entryData);
        _sleepEntries = entriesJson.map((json) => SleepEntry.fromJson(json)).toList();
        debugPrint('Loaded ${_sleepEntries.length} sleep entries from SharedPreferences');
      } else {
        _sleepEntries = [];
        debugPrint('No sleep entries found in storage');
      }
    } catch (e) {
      debugPrint('Error loading sleep entries: $e');
      _sleepEntries = [];
    }
  }
  
  Future<void> _saveSleepEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = _sleepEntries.map((entry) => entry.toJson()).toList();
      final encoded = jsonEncode(entriesJson);
      await prefs.setString(_sleepStorageKey, encoded);
      debugPrint('Saved ${_sleepEntries.length} sleep entries to SharedPreferences');
    } catch (e) {
      debugPrint('Error saving sleep entries: $e');
    }
  }
  
  Future<void> addSleepEntry(SleepEntry entry) async {
    _sleepEntries.add(entry);
    
    if (_useFirestore) {
      // Save to Firestore
      await _firestoreService.saveSleepEntry(entry);
      debugPrint('Saved sleep entry to Firestore');
    } else {
      // Save to SharedPreferences
      await _saveSleepEntries();
    }
  }
  
  Future<void> deleteSleepEntry(String id) async {
    _sleepEntries.removeWhere((entry) => entry.id == id);
    
    if (_useFirestore) {
      // Delete from Firestore
      await _firestoreService.deleteSleepEntry(id);
      debugPrint('Deleted sleep entry from Firestore');
    } else {
      // Save to SharedPreferences
      await _saveSleepEntries();
    }
  }
  
  List<SleepEntry> getAllSleepEntries() {
    return List<SleepEntry>.from(_sleepEntries);
  }
  
  SleepEntry? getLatestSleepEntry() {
    if (_sleepEntries.isEmpty) return null;
    
    final entries = List<SleepEntry>.from(_sleepEntries);
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries.first;
  }
  
  List<SleepEntry> getSleepEntriesByDateRange(DateTime start, DateTime end) {
    return _sleepEntries.where((entry) {
      return entry.date.isAfter(start) && entry.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }
  
  // --- Training entries ---
  
  Future<void> _loadTrainingEntries() async {
    try {
      // For training entries, we'll use the training service data
      // This is just a stub method for now
      _trainingEntries = [];
    } catch (e) {
      debugPrint('Error loading training entries: $e');
      _trainingEntries = [];
    }
  }
  
  // Training statistics
  TrainingStats getTrainingStats() {
    // Use the local training entries - in a real implementation
    // this would be populated from the TrainingService
    if (_trainingEntries.isEmpty) {
      return TrainingStats();
    }
    
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    
    // Start of current week (Monday)
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);
    
    int totalSessions = _trainingEntries.length;
    int currentYearSessions = 0;
    int currentMonthSessions = 0;
    int currentWeekSessions = 0;
    double totalCaloriesBurned = 0;
    double totalHours = 0;
    
    for (final training in _trainingEntries) {
      // Count sessions
      if (training.date.year == currentYear) {
        currentYearSessions++;
        
        if (training.date.month == currentMonth) {
          currentMonthSessions++;
        }
        
        if (training.date.isAfter(startOfWeek)) {
          currentWeekSessions++;
        }
      }
      
      // Sum calories and hours
      totalCaloriesBurned += training.calories;
      totalHours += training.duration / 60.0; // Convert minutes to hours
    }
    
    return TrainingStats(
      totalSessions: totalSessions,
      currentYearSessions: currentYearSessions,
      currentMonthSessions: currentMonthSessions,
      currentWeekSessions: currentWeekSessions,
      totalCaloriesBurned: totalCaloriesBurned,
      totalHours: totalHours,
    );
  }
  
  // Calculate walking calories based on steps, weight, height, gender, and stride length
  int calculateWalkingCalories({
    required int steps, 
    required double weightKg, 
    required double heightCm, 
    required String gender,
    double? strideLength,
    double? userProvidedStrideLength,
    bool isHilly = false,
    bool isCarryingWeight = false,
    double? metOverride,
  }) {
    // First check if user has manually provided a stride length in settings
    if (userProvidedStrideLength != null && userProvidedStrideLength > 0) {
      strideLength = userProvidedStrideLength;
      print('Using user-provided stride length: $strideLength meters');
    } 
    // If no user-provided or passed stride length, calculate it from height and gender
    else if (strideLength == null) {
      // Calculate stride more precisely based on height and gender
      if (gender.toLowerCase() == 'male') {
        // For men: account for height differently for very tall men
        if (heightCm > 185) {
          strideLength = (heightCm * 0.415 + (heightCm - 185) * 0.06) / 100;
        } else if (heightCm < 165) {
          strideLength = (heightCm * 0.41 + (heightCm - 165) * 0.04) / 100;
        } else {
          strideLength = (heightCm * 0.415) / 100;
        }
      } else {
        // For women: slightly different height adjustment
        if (heightCm > 175) {
          strideLength = (heightCm * 0.413 + (heightCm - 175) * 0.055) / 100;
        } else if (heightCm < 155) {
          strideLength = (heightCm * 0.41 + (heightCm - 155) * 0.035) / 100;
        } else {
          strideLength = (heightCm * 0.413) / 100;
        }
      }
      
      // Ensure minimum and maximum reasonable values
      strideLength = math.max(0.5, math.min(1.2, strideLength));
      print('Calculated stride length: $strideLength meters (height: $heightCm cm, gender: $gender)');
    }
    
    // Calculate total distance in kilometers with more precise stride
    final distanceMeters = steps * strideLength;
    final distanceKm = distanceMeters / 1000;
    print('Distance walked: ${distanceKm.toStringAsFixed(2)} km from $steps steps');
    
    // Estimate time spent walking based on a more accurate walking speed formula
    // Base walking speed varies with height
    final heightFactor = heightCm / 170.0;
    // Adjust base speed according to gender (women walk slightly slower on average)
    final genderBaseSpeed = gender.toLowerCase() == 'male' ? 4.4 : 4.2;
    // Taller people walk faster, but not linearly with height
    final walkingSpeed = genderBaseSpeed * math.pow(heightFactor, 0.42);
    print('Estimated walking speed: ${walkingSpeed.toStringAsFixed(2)} km/h');
    
    // Calculate MET value based on walking speed with finer gradations
    // If metOverride is provided, use that instead
    double met;
    
    if (metOverride != null) {
      met = metOverride;
      print('Using manual MET override: $met');
    } else {
      // Base MET values adjusted to be slightly lower across the board
      if (walkingSpeed < 2.8) {
        met = 2.0; // Very slow walking
      } else if (walkingSpeed < 3.2) {
        met = 2.2; // Slow walking
      } else if (walkingSpeed < 3.8) {
        met = 2.5; // Casual walking
      } else if (walkingSpeed < 4.5) {
        met = 2.9; // Normal walking
      } else if (walkingSpeed < 5.2) {
        met = 3.3; // Brisk walking
      } else if (walkingSpeed < 5.8) {
        met = 3.6; // Fast walking
      } else if (walkingSpeed < 6.5) {
        met = 4.0; // Very brisk walking
      } else if (walkingSpeed < 7.2) {
        met = 4.5; // Speed walking
      } else {
        met = 5.0; // Very fast walking/light jogging
      }
      
      // Apply adjustments for terrain and load
      if (isHilly) {
        met += 0.5; // Walking uphill or on uneven terrain increases MET
      }
      
      if (isCarryingWeight) {
        met += 0.4; // Carrying weight increases MET
      }
    }
    print('Calculated MET value: $met');
    
    // Calculate time in hours using actual walking speed
    final timeHours = distanceKm / walkingSpeed;
    print('Time spent walking: ${(timeHours * 60).toStringAsFixed(0)} minutes');
    
    // Apply the standard MET formula as the primary calculation method
    // Calories = MET × weight (kg) × time (hours)
    var calories = met * weightKg * timeHours;
    print('Base MET calculation: ${calories.round()} kcal');
    
    // Apply a smaller correction factor - reduce overestimation
    calories *= 0.98;
    
    // Apply more modest gender-specific adjustment
    if (gender.toLowerCase() == 'male') {
      calories *= 1.03;
    } else {
      calories *= 0.97;
    }
    
    // Apply a more conservative height adjustment
    final heightAdjustment = 1.0 + (heightCm - 170) / 1500; // Reduced from 1000
    calories *= heightAdjustment;
    
    // For heavier individuals, apply a more conservative adjustment to prevent overestimation
    if (weightKg > 90) {
      // The heavier the person, the more we reduce the multiplier to avoid overestimation
      final weightAdjustmentFactor = math.max(0.93, 1.0 - (weightKg - 90) * 0.0015);
      calories *= weightAdjustmentFactor;
      print('Applied weight adjustment factor: $weightAdjustmentFactor for weight $weightKg kg');
    }
    
    // Print final calculation result with all factors
    final result = calories.round();
    print('Final calorie burn: $result kcal (weight: $weightKg kg)');
    
    // As a sanity check, calculate using the simplified formula often used
    // in fitness calculators: 0.04 * weight(kg) * steps
    final simplifiedCalories = 0.04 * weightKg * steps;
    print('Simplified calculation (for comparison): ${simplifiedCalories.round()} kcal');
    
    return result;
  }
  
  // Calculate average stride length based on a known distance and step count
  double calculateStrideLength({required double distanceMeters, required int steps}) {
    if (steps <= 0 || distanceMeters <= 0) {
      throw ArgumentError('Both distance and steps must be positive values');
    }
    
    final strideLength = distanceMeters / steps;
    
    // Validate against reasonable values (0.4m - 1.2m)
    if (strideLength < 0.4 || strideLength > 1.2) {
      print('Warning: Calculated stride length ($strideLength m) seems unusual. ' 'Consider recounting steps or remeasuring distance.');
    }
    
    return strideLength;
  }
  
  // Helper method to estimate stride length from height and gender
  // Can be used independently in the app to give users a starting point
  double estimateStrideLength({required double heightCm, required String gender}) {
    double strideLength;
    
    // Calculate stride precisely based on height and gender
    if (gender.toLowerCase() == 'male') {
      // For men: account for height differently for very tall men
      if (heightCm > 185) {
        strideLength = (heightCm * 0.415 + (heightCm - 185) * 0.06) / 100;
      } else if (heightCm < 165) {
        strideLength = (heightCm * 0.41 + (heightCm - 165) * 0.04) / 100;
      } else {
        strideLength = (heightCm * 0.415) / 100;
      }
    } else {
      // For women: slightly different height adjustment
      if (heightCm > 175) {
        strideLength = (heightCm * 0.413 + (heightCm - 175) * 0.055) / 100;
      } else if (heightCm < 155) {
        strideLength = (heightCm * 0.41 + (heightCm - 155) * 0.035) / 100;
      } else {
        strideLength = (heightCm * 0.413) / 100;
      }
    }
    
    // Ensure reasonable values
    return math.max(0.5, math.min(1.2, strideLength));
  }
  
  // New method to get active energy burned directly from Apple Health
  Future<int> getActiveEnergyBurnedForDay(DateTime date) async {
    try {
      final midnight = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      // Initialize the HealthFactory
      final HealthFactory health = HealthFactory(useHealthConnectIfAvailable: false);
      
      // Request authorization for active energy
      final types = [HealthDataType.ACTIVE_ENERGY_BURNED];
      final permissions = types.map((e) => HealthDataAccess.READ).toList();
      final authorized = await health.requestAuthorization(types, permissions: permissions);
      
      if (authorized) {
        // Fetch Active Energy Burned data
        final activeEnergyData = await health.getHealthDataFromTypes(
          midnight, 
          endOfDay, 
          [HealthDataType.ACTIVE_ENERGY_BURNED]
        );
        
        if (activeEnergyData.isNotEmpty) {
          // Sum up all active energy data points 
          int totalActiveCalories = 0;
          Map<String, int> sourceBreakdown = {};
          
          for (final dataPoint in activeEnergyData) {
            final calories = (dataPoint.value as NumericHealthValue).numericValue.toInt();
            final source = dataPoint.sourceName;
            
            // Track calories by source for debugging
            if (sourceBreakdown.containsKey(source)) {
              sourceBreakdown[source] = (sourceBreakdown[source] ?? 0) + calories;
            } else {
              sourceBreakdown[source] = calories;
            }
            
            totalActiveCalories += calories;
          }
          
          // Log breakdown by source
          sourceBreakdown.forEach((source, calories) {
            print('Active Energy Burned - Source: $source, Calories: $calories');
          });
          
          print('Total Active Energy Burned from Apple Health: $totalActiveCalories calories');
          return totalActiveCalories;
        }
      }
      
      // If there's no Active Energy data or no authorization, return 0
      print('No Active Energy Burned data available in Apple Health');
      return 0;
    } catch (e) {
      print('Error fetching Active Energy Burned: $e');
      return 0;
    }
  }
} 