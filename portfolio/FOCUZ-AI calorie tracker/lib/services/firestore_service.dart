import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/health_data.dart';
import '../models/training.dart';
import '../models/meal_data.dart';
import 'dart:convert';

/// Service for handling Firestore database operations and migration from SharedPreferences
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  
  // Singleton pattern
  factory FirestoreService() {
    return _instance;
  }
  
  FirestoreService._internal();
  
  // Firebase instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Flag to prevent simultaneous migrations
  bool _isMigrating = false;
  
  // Track migration status
  bool _migrationCompleted = false;
  
  // Getters
  bool get isMigrating => _isMigrating;
  bool get migrationCompleted => _migrationCompleted;
  
  // Check if user is authenticated
  bool get isUserAuthenticated => _auth.currentUser != null;
  
  // Get current user ID (default to 'default_user' if not authenticated)
  String get userId => _auth.currentUser?.uid ?? 'default_user';
  
  /// Initialize the service and check migration status
  Future<void> init() async {
    try {
      if (isUserAuthenticated) {
        // Check if migration has been completed
        final prefs = await SharedPreferences.getInstance();
        _migrationCompleted = prefs.getBool('firestore_migration_completed_${userId}') ?? false;
        
        if (!_migrationCompleted) {
          // Schedule migration for after app is fully initialized
          Future.delayed(const Duration(seconds: 2), () {
            migrateFromSharedPreferences();
          });
        }
      }
    } catch (e) {
      print('Error initializing FirestoreService: $e');
    }
  }
  
  /// Sign in anonymously to ensure we have a user ID
  Future<void> signInAnonymously() async {
    if (!isUserAuthenticated) {
      try {
        await _auth.signInAnonymously();
        print('Signed in anonymously: ${userId}');
      } catch (e) {
        print('Error signing in anonymously: $e');
      }
    }
  }
  
  /// Migrate data from SharedPreferences to Firestore
  Future<void> migrateFromSharedPreferences() async {
    if (_isMigrating || _migrationCompleted) return;
    
    _isMigrating = true;
    print('Starting migration from SharedPreferences to Firestore');
    
    try {
      // Ensure we have a user to associate data with
      if (!isUserAuthenticated) {
        await signInAnonymously();
      }
      
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Migrate weight entries
      await _migrateWeightEntries(prefs);
      
      // 2. Migrate water entries
      await _migrateWaterEntries(prefs);
      
      // 3. Migrate sleep entries
      await _migrateSleepEntries(prefs);
      
      // 4. Migrate training entries
      await _migrateTrainingEntries(prefs);
      
      // 5. Migrate meal entries
      await _migrateMealEntries(prefs);
      
      // 6. Migrate custom meals
      await _migrateCustomMeals(prefs);
      
      // 7. Migrate nutrition profile
      await _migrateNutritionProfile(prefs);
      
      // Mark migration as completed
      await prefs.setBool('firestore_migration_completed_${userId}', true);
      _migrationCompleted = true;
      
      print('Migration completed successfully');
    } catch (e) {
      print('Error during migration: $e');
    } finally {
      _isMigrating = false;
    }
  }
  
  /// Migrate weight entries from SharedPreferences to Firestore
  Future<void> _migrateWeightEntries(SharedPreferences prefs) async {
    try {
      final weightEntriesJson = prefs.getString('weight_entries');
      if (weightEntriesJson != null) {
        final List<dynamic> weightEntriesList = jsonDecode(weightEntriesJson);
        final batch = _firestore.batch();
        
        for (final entryJson in weightEntriesList) {
          final weightEntry = WeightEntry.fromJson(entryJson);
          final docRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('weight_entries')
              .doc(weightEntry.id);
          
          batch.set(docRef, weightEntry.toJson());
        }
        
        await batch.commit();
        print('Migrated ${weightEntriesList.length} weight entries');
      }
    } catch (e) {
      print('Error migrating weight entries: $e');
    }
  }
  
  /// Migrate water entries from SharedPreferences to Firestore
  Future<void> _migrateWaterEntries(SharedPreferences prefs) async {
    try {
      final waterEntriesJson = prefs.getString('water_entries');
      if (waterEntriesJson != null) {
        final List<dynamic> waterEntriesList = jsonDecode(waterEntriesJson);
        final batch = _firestore.batch();
        
        for (final entryJson in waterEntriesList) {
          final waterEntry = WaterEntry.fromJson(entryJson);
          final docRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('water_entries')
              .doc(waterEntry.id);
          
          batch.set(docRef, waterEntry.toJson());
        }
        
        await batch.commit();
        print('Migrated ${waterEntriesList.length} water entries');
      }
    } catch (e) {
      print('Error migrating water entries: $e');
    }
  }
  
  /// Migrate sleep entries from SharedPreferences to Firestore
  Future<void> _migrateSleepEntries(SharedPreferences prefs) async {
    try {
      final sleepEntriesJson = prefs.getString('sleep_entries');
      if (sleepEntriesJson != null) {
        final List<dynamic> sleepEntriesList = jsonDecode(sleepEntriesJson);
        final batch = _firestore.batch();
        
        for (final entryJson in sleepEntriesList) {
          final sleepEntry = SleepEntry.fromJson(entryJson);
          final docRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('sleep_entries')
              .doc(sleepEntry.id);
          
          batch.set(docRef, sleepEntry.toJson());
        }
        
        await batch.commit();
        print('Migrated ${sleepEntriesList.length} sleep entries');
      }
    } catch (e) {
      print('Error migrating sleep entries: $e');
    }
  }
  
  /// Migrate training entries from SharedPreferences to Firestore
  Future<void> _migrateTrainingEntries(SharedPreferences prefs) async {
    try {
      final trainingsJson = prefs.getString('trainings');
      if (trainingsJson != null) {
        final List<dynamic> trainingsList = jsonDecode(trainingsJson);
        final batch = _firestore.batch();
        
        for (final entryJson in trainingsList) {
          final training = Training.fromJson(entryJson);
          final docRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('trainings')
              .doc(training.id);
          
          batch.set(docRef, training.toJson());
        }
        
        await batch.commit();
        print('Migrated ${trainingsList.length} training entries');
      }
      
      // Migrate training stats
      final trainingStatsJson = prefs.getString('training_stats');
      if (trainingStatsJson != null) {
        final trainingStats = TrainingStats.fromJson(jsonDecode(trainingStatsJson));
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('stats')
            .doc('training')
            .set(trainingStats.toJson());
        
        print('Migrated training stats');
      }
    } catch (e) {
      print('Error migrating training entries: $e');
    }
  }
  
  /// Migrate meal entries from SharedPreferences to Firestore
  Future<void> _migrateMealEntries(SharedPreferences prefs) async {
    try {
      final mealEntriesJson = prefs.getString('meal_entries');
      if (mealEntriesJson != null) {
        final List<dynamic> mealEntriesList = jsonDecode(mealEntriesJson);
        final batch = _firestore.batch();
        
        for (final entryJson in mealEntriesList) {
          final mealEntry = MealEntry.fromJson(entryJson);
          final docRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('meal_entries')
              .doc(mealEntry.id);
          
          batch.set(docRef, mealEntry.toJson());
        }
        
        await batch.commit();
        print('Migrated ${mealEntriesList.length} meal entries');
      }
    } catch (e) {
      print('Error migrating meal entries: $e');
    }
  }
  
  /// Migrate custom meals from SharedPreferences to Firestore
  Future<void> _migrateCustomMeals(SharedPreferences prefs) async {
    try {
      final customMealsJson = prefs.getString('custom_meals');
      if (customMealsJson != null) {
        final List<dynamic> customMealsList = jsonDecode(customMealsJson);
        final batch = _firestore.batch();
        
        for (final entryJson in customMealsList) {
          final customMeal = CustomMeal.fromJson(entryJson);
          final docRef = _firestore
              .collection('users')
              .doc(userId)
              .collection('custom_meals')
              .doc(customMeal.id);
          
          batch.set(docRef, customMeal.toJson());
        }
        
        await batch.commit();
        print('Migrated ${customMealsList.length} custom meals');
      }
    } catch (e) {
      print('Error migrating custom meals: $e');
    }
  }
  
  /// Migrate nutrition profile from SharedPreferences to Firestore
  Future<void> _migrateNutritionProfile(SharedPreferences prefs) async {
    try {
      final nutritionProfileJson = prefs.getString('nutrition_profile');
      if (nutritionProfileJson != null) {
        final nutritionProfile = NutritionProfile.fromJson(jsonDecode(nutritionProfileJson));
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('profiles')
            .doc('nutrition')
            .set(nutritionProfile.toJson());
        
        print('Migrated nutrition profile');
      }
    } catch (e) {
      print('Error migrating nutrition profile: $e');
    }
  }
  
  /// CRUD Operations for Weight Entries
  
  // Save a weight entry
  Future<void> saveWeightEntry(WeightEntry entry) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('weight_entries')
          .doc(entry.id)
          .set(entry.toJson());
    } catch (e) {
      print('Error saving weight entry: $e');
      throw e;
    }
  }
  
  // Get all weight entries
  Future<List<WeightEntry>> getAllWeightEntries() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('weight_entries')
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => WeightEntry.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting weight entries: $e');
      return [];
    }
  }
  
  // Delete a weight entry
  Future<void> deleteWeightEntry(String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('weight_entries')
          .doc(id)
          .delete();
    } catch (e) {
      print('Error deleting weight entry: $e');
      throw e;
    }
  }
  
  /// CRUD Operations for Water Entries
  
  // Save a water entry
  Future<void> saveWaterEntry(WaterEntry entry) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('water_entries')
          .doc(entry.id)
          .set(entry.toJson());
    } catch (e) {
      print('Error saving water entry: $e');
      throw e;
    }
  }
  
  // Get all water entries
  Future<List<WaterEntry>> getAllWaterEntries() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('water_entries')
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => WaterEntry.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting water entries: $e');
      return [];
    }
  }
  
  // Get water entries for a specific day
  Future<List<WaterEntry>> getWaterEntriesForDay(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('water_entries')
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .get();
      
      return snapshot.docs
          .map((doc) => WaterEntry.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting water entries for day: $e');
      return [];
    }
  }
  
  // Delete a water entry
  Future<void> deleteWaterEntry(String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('water_entries')
          .doc(id)
          .delete();
    } catch (e) {
      print('Error deleting water entry: $e');
      throw e;
    }
  }
  
  /// CRUD Operations for Sleep Entries
  
  // Save a sleep entry
  Future<void> saveSleepEntry(SleepEntry entry) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sleep_entries')
          .doc(entry.id)
          .set(entry.toJson());
    } catch (e) {
      print('Error saving sleep entry: $e');
      throw e;
    }
  }
  
  // Get all sleep entries
  Future<List<SleepEntry>> getAllSleepEntries() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sleep_entries')
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => SleepEntry.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting sleep entries: $e');
      return [];
    }
  }
  
  // Delete a sleep entry
  Future<void> deleteSleepEntry(String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sleep_entries')
          .doc(id)
          .delete();
    } catch (e) {
      print('Error deleting sleep entry: $e');
      throw e;
    }
  }
  
  /// CRUD Operations for Training Entries
  
  // Save a training entry
  Future<void> saveTraining(Training training) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('trainings')
          .doc(training.id)
          .set(training.toJson());
    } catch (e) {
      print('Error saving training: $e');
      throw e;
    }
  }
  
  // Get all training entries
  Future<List<Training>> getAllTrainings() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('trainings')
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Training.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting trainings: $e');
      return [];
    }
  }
  
  // Get trainings for a specific day
  Future<List<Training>> getTrainingsForDay(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('trainings')
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .get();
      
      return snapshot.docs
          .map((doc) => Training.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting trainings for day: $e');
      return [];
    }
  }
  
  // Delete a training entry
  Future<void> deleteTraining(String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('trainings')
          .doc(id)
          .delete();
    } catch (e) {
      print('Error deleting training: $e');
      throw e;
    }
  }
  
  // Save training stats
  Future<void> saveTrainingStats(TrainingStats stats) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('training')
          .set(stats.toJson());
    } catch (e) {
      print('Error saving training stats: $e');
      throw e;
    }
  }
  
  // Get training stats
  Future<TrainingStats?> getTrainingStats() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('stats')
          .doc('training')
          .get();
      
      if (doc.exists) {
        return TrainingStats.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting training stats: $e');
      return null;
    }
  }
  
  /// CRUD Operations for Meal Entries
  
  // Save a meal entry
  Future<void> saveMealEntry(MealEntry entry) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('meal_entries')
          .doc(entry.id)
          .set(entry.toJson());
    } catch (e) {
      print('Error saving meal entry: $e');
      throw e;
    }
  }
  
  // Get all meal entries
  Future<List<MealEntry>> getAllMealEntries() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('meal_entries')
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => MealEntry.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting meal entries: $e');
      return [];
    }
  }
  
  // Get meal entries for a specific day
  Future<List<MealEntry>> getMealEntriesForDay(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('meal_entries')
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .get();
      
      return snapshot.docs
          .map((doc) => MealEntry.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting meal entries for day: $e');
      return [];
    }
  }
  
  // Delete a meal entry
  Future<void> deleteMealEntry(String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('meal_entries')
          .doc(id)
          .delete();
    } catch (e) {
      print('Error deleting meal entry: $e');
      throw e;
    }
  }
  
  /// CRUD Operations for Custom Meals
  
  // Save a custom meal
  Future<void> saveCustomMeal(CustomMeal meal) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('custom_meals')
          .doc(meal.id)
          .set(meal.toJson());
    } catch (e) {
      print('Error saving custom meal: $e');
      throw e;
    }
  }
  
  // Get all custom meals
  Future<List<CustomMeal>> getAllCustomMeals() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('custom_meals')
          .orderBy('name')
          .get();
      
      return snapshot.docs
          .map((doc) => CustomMeal.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting custom meals: $e');
      return [];
    }
  }
  
  // Delete a custom meal
  Future<void> deleteCustomMeal(String id) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('custom_meals')
          .doc(id)
          .delete();
    } catch (e) {
      print('Error deleting custom meal: $e');
      throw e;
    }
  }
  
  /// CRUD Operations for Nutrition Profile
  
  // Save nutrition profile
  Future<void> saveNutritionProfile(NutritionProfile profile) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('profiles')
          .doc('nutrition')
          .set(profile.toJson());
    } catch (e) {
      print('Error saving nutrition profile: $e');
      throw e;
    }
  }
  
  // Get nutrition profile
  Future<NutritionProfile?> getNutritionProfile() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('profiles')
          .doc('nutrition')
          .get();
      
      if (doc.exists) {
        return NutritionProfile.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting nutrition profile: $e');
      return null;
    }
  }
} 