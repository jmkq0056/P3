import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/health_data.dart';
import '../models/training.dart';
import '../models/meal_data.dart';
import 'dart:convert';
import 'package:flutter/material.dart' hide TimeOfDay;

/// Service to handle migration of data from SharedPreferences to Firebase
class MigrationService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final SharedPreferences _prefs;
  
  /// Initialize the migration service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  /// Check if migration has already been completed
  Future<bool> isMigrationCompleted() async {
    return _prefs.getBool('migration_completed') ?? false;
  }
  
  /// Mark migration as completed
  Future<void> markMigrationCompleted() async {
    await _prefs.setBool('migration_completed', true);
  }
  
  /// Migrate SharedPreferences data to Firebase
  Future<bool> migrateSharedPreferencesToFirebase() async {
    try {
      // Check if migration is already completed
      if (await isMigrationCompleted()) {
        print('Migration already completed');
        return true;
      }
      
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in, cannot migrate data');
        return false;
      }
      
      // Get all preference keys
      final keys = _prefs.getKeys();
      
      // Prepare data for each collection
      final userData = <String, dynamic>{};
      final sleepEntries = <Map<String, dynamic>>[];
      final calorieEntries = <Map<String, dynamic>>[];
      final waterEntries = <Map<String, dynamic>>[];
      final weightEntries = <Map<String, dynamic>>[];
      final trainingEntries = <Map<String, dynamic>>[];
      
      // Sort keys into categories
      for (final key in keys) {
        if (key.startsWith('user_')) {
          // User profile data
          final userKey = key.replaceFirst('user_', '');
          userData[userKey] = _getPreferenceValue(key);
        } else if (key.startsWith('sleep_')) {
          // Sleep entries
          _extractEntryData(key, 'sleep_', sleepEntries);
        } else if (key.startsWith('calorie_') || key.startsWith('meal_')) {
          // Calorie/meal entries
          _extractEntryData(key, key.startsWith('calorie_') ? 'calorie_' : 'meal_', calorieEntries);
        } else if (key.startsWith('water_')) {
          // Water entries
          _extractEntryData(key, 'water_', waterEntries);
        } else if (key.startsWith('weight_')) {
          // Weight entries
          _extractEntryData(key, 'weight_', weightEntries);
        } else if (key.startsWith('training_')) {
          // Training entries
          _extractEntryData(key, 'training_', trainingEntries);
        }
      }
      
      // Save user data
      if (userData.isNotEmpty) {
        // Add migration timestamp and user ID
        userData['migrated_at'] = DateTime.now().toIso8601String();
        userData['user_id'] = user.uid;
        
        // Store user data in Firestore users collection
        await _firestore.collection('users').doc(user.uid).set(userData);
      }
      
      // Save sleep entries
      for (final entry in sleepEntries) {
        // Add user ID to each entry
        entry['user_id'] = user.uid;
        final entryId = entry['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
        
        // Convert to SleepEntry model then save
        try {
          // Create a properly formatted SleepEntry
          final sleepEntry = _createSleepEntryFromMap(entry);
          await _firestoreService.saveSleepEntry(sleepEntry);
        } catch (e) {
          print('Error saving sleep entry: $e');
          // Save raw data as fallback
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('sleep_entries')
              .doc(entryId)
              .set(entry);
        }
      }
      
      // Save meal entries
      for (final entry in calorieEntries) {
        // Add user ID to each entry
        entry['user_id'] = user.uid;
        final entryId = entry['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
        
        // Convert to MealEntry model then save
        try {
          // Create a properly formatted MealEntry
          final mealEntry = _createMealEntryFromMap(entry);
          await _firestoreService.saveMealEntry(mealEntry);
        } catch (e) {
          print('Error saving meal entry: $e');
          // Save raw data as fallback
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('meal_entries')
              .doc(entryId)
              .set(entry);
        }
      }
      
      // Save water entries
      for (final entry in waterEntries) {
        // Add user ID to each entry
        entry['user_id'] = user.uid;
        final entryId = entry['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
        
        // Convert to WaterEntry model then save
        try {
          // Create a properly formatted WaterEntry
          final waterEntry = _createWaterEntryFromMap(entry);
          await _firestoreService.saveWaterEntry(waterEntry);
        } catch (e) {
          print('Error saving water entry: $e');
          // Save raw data as fallback
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('water_entries')
              .doc(entryId)
              .set(entry);
        }
      }
      
      // Save weight entries
      for (final entry in weightEntries) {
        // Add user ID to each entry
        entry['user_id'] = user.uid;
        final entryId = entry['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
        
        // Convert to WeightEntry model then save
        try {
          // Create a properly formatted WeightEntry
          final weightEntry = _createWeightEntryFromMap(entry);
          await _firestoreService.saveWeightEntry(weightEntry);
        } catch (e) {
          print('Error saving weight entry: $e');
          // Save raw data as fallback
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('weight_entries')
              .doc(entryId)
              .set(entry);
        }
      }
      
      // Save training entries
      for (final entry in trainingEntries) {
        // Add user ID to each entry
        entry['user_id'] = user.uid;
        final entryId = entry['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
        
        // Convert to Training model then save
        try {
          // Create a properly formatted Training
          final training = _createTrainingFromMap(entry);
          await _firestoreService.saveTraining(training);
        } catch (e) {
          print('Error saving training entry: $e');
          // Save raw data as fallback
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('trainings')
              .doc(entryId)
              .set(entry);
        }
      }
      
      // Mark migration as completed
      await markMigrationCompleted();
      
      print('Migration completed successfully');
      return true;
    } catch (e) {
      print('Error during migration: $e');
      return false;
    }
  }
  
  /// Extract entry data from SharedPreferences key
  void _extractEntryData(String key, String prefix, List<Map<String, dynamic>> entries) {
    try {
      final value = _getPreferenceValue(key);
      if (value != null) {
        // For keys with timestamps (e.g., sleep_20220101)
        if (key.length > prefix.length && int.tryParse(key.substring(prefix.length)) != null) {
          final timestamp = key.substring(prefix.length);
          final entry = {
            'id': timestamp,
            'timestamp': timestamp,
            'value': value,
            'date': DateTime.now().toIso8601String(), // Add a default date
          };
          entries.add(entry);
        } 
        // For structured data (e.g., sleep_duration, sleep_quality)
        else {
          final dataKey = key.replaceFirst(prefix, '');
          // Check if we have an existing entry with this ID
          var found = false;
          for (final entry in entries) {
            if (entry['type'] == prefix.replaceAll('_', '')) {
              entry[dataKey] = value;
              found = true;
              break;
            }
          }
          // Create a new entry if not found
          if (!found) {
            final entry = {
              'type': prefix.replaceAll('_', ''),
              dataKey: value,
              'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
              'date': DateTime.now().toIso8601String(), // Add a default date
              'id': DateTime.now().millisecondsSinceEpoch.toString(), // Add a default id
            };
            entries.add(entry);
          }
        }
      }
    } catch (e) {
      print('Error extracting entry data from key $key: $e');
    }
  }
  
  /// Get value from SharedPreferences based on key
  dynamic _getPreferenceValue(String key) {
    if (_prefs.containsKey(key)) {
      if (_prefs.getString(key) != null) return _prefs.getString(key);
      if (_prefs.getBool(key) != null) return _prefs.getBool(key);
      if (_prefs.getInt(key) != null) return _prefs.getInt(key);
      if (_prefs.getDouble(key) != null) return _prefs.getDouble(key);
      if (_prefs.getStringList(key) != null) return _prefs.getStringList(key);
    }
    return null;
  }
  
  /// Create a SleepEntry from a map
  SleepEntry _createSleepEntryFromMap(Map<String, dynamic> map) {
    // Ensure we have the required fields
    final String id = map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final DateTime date = map['date'] != null 
        ? DateTime.parse(map['date']) 
        : DateTime.now();
    
    // Create default bedTime and wakeTime if not available
    final DateTime bedTime = map['bedTime'] != null 
        ? DateTime.parse(map['bedTime']) 
        : date.subtract(const Duration(hours: 8));
    final DateTime wakeTime = map['wakeTime'] != null 
        ? DateTime.parse(map['wakeTime']) 
        : date;
    
    return SleepEntry(
      id: id,
      date: date,
      bedTime: bedTime,
      wakeTime: wakeTime,
      quality: map['quality'] ?? 3, // Default quality
      note: map['note'],
    );
  }
  
  /// Create a WaterEntry from a map
  WaterEntry _createWaterEntryFromMap(Map<String, dynamic> map) {
    // Ensure we have the required fields
    final String id = map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final DateTime date = map['date'] != null 
        ? DateTime.parse(map['date']) 
        : DateTime.now();
    
    return WaterEntry(
      id: id,
      date: date,
      amount: _parseDouble(map['amount'] ?? 250), // Default 250ml
      type: map['type'] ?? 'water', // Default type
    );
  }
  
  /// Create a WeightEntry from a map
  WeightEntry _createWeightEntryFromMap(Map<String, dynamic> map) {
    // Ensure we have the required fields
    final String id = map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final DateTime date = map['date'] != null 
        ? DateTime.parse(map['date']) 
        : DateTime.now();
    
    return WeightEntry(
      id: id,
      date: date,
      weight: _parseDouble(map['weight'] ?? 70), // Default 70kg
      note: map['note'],
    );
  }
  
  /// Create a MealEntry from a map
  MealEntry _createMealEntryFromMap(Map<String, dynamic> map) {
    // Ensure we have the required fields
    final String id = map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final DateTime date = map['date'] != null 
        ? DateTime.parse(map['date']) 
        : DateTime.now();
    
    // Create TimeOfDay
    final timeOfDay = TimeOfDay(
      hour: map['timeOfDay']?['hour'] ?? 12,
      minute: map['timeOfDay']?['minute'] ?? 0,
    );
    
    return MealEntry(
      id: id,
      date: date,
      name: map['name'] ?? 'Meal',
      calories: map['calories'] ?? 0,
      mealType: map['mealType'] ?? 'snack',
      timeOfDay: timeOfDay,
      portion: map['portion'],
      macros: map['macros'] != null ? Macros.fromJson(map['macros']) : null,
    );
  }
  
  /// Create a Training from a map
  Training _createTrainingFromMap(Map<String, dynamic> map) {
    // Ensure we have the required fields
    final String id = map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final DateTime date = map['date'] != null 
        ? DateTime.parse(map['date']) 
        : DateTime.now();
    
    return Training(
      id: id,
      title: map['title'] ?? 'Training',
      date: date,
      calories: map['calories'] ?? 0,
      duration: map['duration'] ?? 30, // Default 30 minutes
      type: map['type'] ?? 'workout',
      videoUrl: map['videoPath'] ?? map['videoUrl'], // Support both old videoPath and new videoUrl
    );
  }
  
  /// Helper to parse double values from various formats
  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }
} 