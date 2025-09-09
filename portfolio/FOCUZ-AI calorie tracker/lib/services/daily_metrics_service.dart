import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_metrics.dart';
import '../services/firestore_service.dart';

class DailyMetricsService {
  static const String _metricsStorageKey = 'daily_metrics';
  static const String _waterEntriesStorageKey = 'water_entries';
  
  // Cache data in memory
  Map<String, DailyMetrics> _metricsCache = {}; // Key: dateKey (YYYY-MM-DD)
  List<WaterEntry> _waterEntriesCache = [];
  
  // Track initialization state
  bool _isInitializing = false;
  bool _isInitialized = false;
  String? _initError;
  
  // Firestore service
  final FirestoreService _firestoreService = FirestoreService();
  
  // Flag to track if data should be loaded from local or Firestore
  bool _useFirestore = false;

  // Initialize service
  Future<void> init() async {
    if (_isInitialized) return;
    
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }
    
    _isInitializing = true;
    
    try {
      // Check if migration is completed
      final prefs = await SharedPreferences.getInstance();
      final migrationKey = 'firestore_migration_completed_${_firestoreService.userId}';
      _useFirestore = prefs.getBool(migrationKey) ?? false;
      
      // Initialize Firestore service
      await _firestoreService.init();
      
      if (_useFirestore) {
        debugPrint('Initializing DailyMetricsService with Firestore...');
        await _loadFromFirestore();
      } else {
        debugPrint('Initializing DailyMetricsService with SharedPreferences...');
        await _loadFromSharedPreferences();
      }
      
      _isInitialized = true;
      debugPrint('DailyMetricsService initialization completed successfully');
    } catch (e) {
      _initError = e.toString();
      debugPrint('Error initializing DailyMetricsService: $e');
      _isInitialized = true;
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  // Load data from SharedPreferences
  Future<void> _loadFromSharedPreferences() async {
    await _loadMetrics();
    await _loadWaterEntries();
  }

  // Load data from Firestore
  Future<void> _loadFromFirestore() async {
    // TODO: Implement Firestore loading when methods are added to FirestoreService
    debugPrint('Firestore loading for daily metrics not yet implemented');
    await _loadFromSharedPreferences(); // Fallback to SharedPreferences for now
  }

  // Load metrics from SharedPreferences
  Future<void> _loadMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metricsData = prefs.getString(_metricsStorageKey);
      
      if (metricsData != null && metricsData.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(metricsData);
        _metricsCache = decoded.map((key, value) => 
            MapEntry(key, DailyMetrics.fromJson(value)));
        debugPrint('Loaded ${_metricsCache.length} daily metrics from SharedPreferences');
      } else {
        _metricsCache = {};
        debugPrint('No daily metrics found in SharedPreferences');
      }
    } catch (e) {
      debugPrint('Error loading daily metrics from SharedPreferences: $e');
      _metricsCache = {};
    }
  }

  // Save metrics to SharedPreferences
  Future<bool> _saveMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metricsData = _metricsCache.map((key, value) => 
          MapEntry(key, value.toJson()));
      final encoded = jsonEncode(metricsData);
      final success = await prefs.setString(_metricsStorageKey, encoded);
      
      if (success) {
        debugPrint('Successfully saved ${_metricsCache.length} daily metrics to SharedPreferences');
      } else {
        debugPrint('Failed to save daily metrics to SharedPreferences');
      }
      
      return success;
    } catch (e) {
      debugPrint('Error saving daily metrics to SharedPreferences: $e');
      return false;
    }
  }

  // Load water entries from SharedPreferences
  Future<void> _loadWaterEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final waterData = prefs.getString(_waterEntriesStorageKey);
      
      if (waterData != null && waterData.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(waterData);
        _waterEntriesCache = decoded.map((item) => WaterEntry.fromJson(item)).toList();
        debugPrint('Loaded ${_waterEntriesCache.length} water entries from SharedPreferences');
      } else {
        _waterEntriesCache = [];
        debugPrint('No water entries found in SharedPreferences');
      }
    } catch (e) {
      debugPrint('Error loading water entries from SharedPreferences: $e');
      _waterEntriesCache = [];
    }
  }

  // Save water entries to SharedPreferences
  Future<bool> _saveWaterEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final waterData = _waterEntriesCache.map((entry) => entry.toJson()).toList();
      final encoded = jsonEncode(waterData);
      final success = await prefs.setString(_waterEntriesStorageKey, encoded);
      
      if (success) {
        debugPrint('Successfully saved ${_waterEntriesCache.length} water entries to SharedPreferences');
      } else {
        debugPrint('Failed to save water entries to SharedPreferences');
      }
      
      return success;
    } catch (e) {
      debugPrint('Error saving water entries to SharedPreferences: $e');
      return false;
    }
  }

  // Helper method to check if initialized
  void _checkInitialized() {
    if (!_isInitialized && _initError != null) {
      throw Exception('DailyMetricsService not properly initialized: $_initError');
    }
  }

  // Get normalized date (removes time component)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Get date key for a date
  String _getDateKey(DateTime date) {
    final normalized = _normalizeDate(date);
    return '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
  }

  // Save or update daily metrics (overrides existing for the same day)
  Future<bool> saveDailyMetrics(DailyMetrics metrics) async {
    await init();
    _checkInitialized();

    try {
      final normalizedDate = _normalizeDate(metrics.date);
      final dateKey = _getDateKey(normalizedDate);
      
      // Create new metrics with normalized date
      final normalizedMetrics = metrics.copyWith(date: normalizedDate);
      
      // Check if metrics already exist for this date
      if (_metricsCache.containsKey(dateKey)) {
        // Merge with existing metrics (override with new values)
        final existingMetrics = _metricsCache[dateKey]!;
        _metricsCache[dateKey] = existingMetrics.mergeWith(normalizedMetrics);
        debugPrint('Updated existing daily metrics for $dateKey');
      } else {
        // Add new metrics
        _metricsCache[dateKey] = normalizedMetrics;
        debugPrint('Added new daily metrics for $dateKey');
      }

      // Save to storage
      final success = await _saveMetrics();
      
      // TODO: Save to Firestore when implemented
      
      return success;
    } catch (e) {
      debugPrint('Error saving daily metrics: $e');
      return false;
    }
  }

  // Get daily metrics for a specific date
  DailyMetrics? getDailyMetrics(DateTime date) {
    _checkInitialized();
    final dateKey = _getDateKey(date);
    return _metricsCache[dateKey];
  }

  // Get daily metrics for a date range
  List<DailyMetrics> getDailyMetricsRange(DateTime startDate, DateTime endDate) {
    _checkInitialized();
    
    final List<DailyMetrics> result = [];
    DateTime currentDate = _normalizeDate(startDate);
    final normalizedEndDate = _normalizeDate(endDate);

    while (currentDate.isBefore(normalizedEndDate) || currentDate.isAtSameMomentAs(normalizedEndDate)) {
      final dateKey = _getDateKey(currentDate);
      final metrics = _metricsCache[dateKey];
      if (metrics != null) {
        result.add(metrics);
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return result;
  }

  // Add water entry
  Future<bool> addWaterEntry(WaterEntry entry) async {
    await init();
    _checkInitialized();

    try {
      _waterEntriesCache.add(entry);
      
      // Also update daily water intake total
      final date = _normalizeDate(entry.timestamp);
      final dateKey = _getDateKey(date);
      
      // Calculate total water intake for the day
      final dayWaterEntries = _waterEntriesCache.where((e) => 
          _getDateKey(e.timestamp) == dateKey).toList();
      final totalWater = dayWaterEntries.fold<double>(0.0, (sum, e) => sum + e.amount);
      
      // Update or create daily metrics with water total
      final existingMetrics = _metricsCache[dateKey];
      final updatedMetrics = existingMetrics?.copyWith(
        waterIntake: totalWater,
      ) ?? DailyMetrics(
        date: date,
        waterIntake: totalWater,
      );
      
      _metricsCache[dateKey] = updatedMetrics;
      
      // Save both water entries and metrics
      final waterSuccess = await _saveWaterEntries();
      final metricsSuccess = await _saveMetrics();
      
      return waterSuccess && metricsSuccess;
    } catch (e) {
      debugPrint('Error adding water entry: $e');
      return false;
    }
  }

  // Get water entries for a date
  List<WaterEntry> getWaterEntriesForDate(DateTime date) {
    _checkInitialized();
    final dateKey = _getDateKey(date);
    return _waterEntriesCache.where((entry) => 
        _getDateKey(entry.timestamp) == dateKey).toList();
  }

  // Get total water intake for a date
  double getTotalWaterForDate(DateTime date) {
    final entries = getWaterEntriesForDate(date);
    return entries.fold<double>(0.0, (sum, entry) => sum + entry.amount);
  }

  // Update steps for a date
  Future<bool> updateSteps(DateTime date, int steps) async {
    await init();
    _checkInitialized();

    final normalizedDate = _normalizeDate(date);
    final dateKey = _getDateKey(normalizedDate);
    
    final existingMetrics = _metricsCache[dateKey];
    final updatedMetrics = existingMetrics?.copyWith(
      steps: steps,
    ) ?? DailyMetrics(
      date: normalizedDate,
      steps: steps,
    );
    
    _metricsCache[dateKey] = updatedMetrics;
    return await _saveMetrics();
  }

  // Update sleep data for a date
  Future<bool> updateSleep(DateTime date, SleepData sleepData) async {
    await init();
    _checkInitialized();

    final normalizedDate = _normalizeDate(date);
    final dateKey = _getDateKey(normalizedDate);
    
    final existingMetrics = _metricsCache[dateKey];
    final updatedMetrics = existingMetrics?.copyWith(
      sleepData: sleepData,
    ) ?? DailyMetrics(
      date: normalizedDate,
      sleepData: sleepData,
    );
    
    _metricsCache[dateKey] = updatedMetrics;
    return await _saveMetrics();
  }

  // Update weight for a date
  Future<bool> updateWeight(DateTime date, double weight) async {
    await init();
    _checkInitialized();

    final normalizedDate = _normalizeDate(date);
    final dateKey = _getDateKey(normalizedDate);
    
    final existingMetrics = _metricsCache[dateKey];
    final updatedMetrics = existingMetrics?.copyWith(
      weight: weight,
    ) ?? DailyMetrics(
      date: normalizedDate,
      weight: weight,
    );
    
    _metricsCache[dateKey] = updatedMetrics;
    return await _saveMetrics();
  }

  // Clear all data (for testing or reset)
  Future<bool> clearAllData() async {
    await init();
    _checkInitialized();

    try {
      _metricsCache.clear();
      _waterEntriesCache.clear();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_metricsStorageKey);
      await prefs.remove(_waterEntriesStorageKey);
      
      debugPrint('Cleared all daily metrics data');
      return true;
    } catch (e) {
      debugPrint('Error clearing daily metrics data: $e');
      return false;
    }
  }
} 