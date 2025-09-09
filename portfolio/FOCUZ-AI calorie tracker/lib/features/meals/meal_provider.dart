import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/foundation.dart';
import '../../services/meal_service.dart';
import '../../models/meal_data.dart';

class MealProvider extends ChangeNotifier {
  final MealService _mealService = MealService();
  bool _isInitialized = false;
  
  MealProvider() {
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    if (!_isInitialized) {
      await _mealService.init();
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  // Add a meal with optional macro details
  Future<void> logMeal(
    String name, 
    int calories, {
    double? protein, 
    double? fat, 
    double? carbs,
    double? fiber,
    String? portion,
    String? mealType,
    bool isLowFat = false,
    String dietType = 'Standard',
    String? imageUrl,
    List<String>? imageUrls,
    double? estimatedWeight,
  }) async {
    await _initializeService(); // Ensure service is initialized
    
    final DateTime now = DateTime.now();
    final TimeOfDay timeOfDay = TimeOfDay(hour: now.hour, minute: now.minute);
    
    Macros? macros;
    if (protein != null || fat != null || carbs != null || fiber != null) {
      macros = Macros(
        proteinGrams: protein ?? 0.0,
        fatGrams: fat ?? 0.0,
        carbsGrams: carbs ?? 0.0,
        fiberGrams: fiber ?? 0.0,
      );
    }
    
    final meal = MealEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      calories: calories,
      mealType: mealType ?? _determineMealType(timeOfDay),
      timeOfDay: timeOfDay,
      date: now,
      macros: macros,
      portion: portion ?? "1 serving",
      isLowFat: isLowFat,
      dietType: dietType,
      imageUrl: imageUrl,
      imageUrls: imageUrls ?? const [],
      estimatedWeight: estimatedWeight ?? 0.0,
    );
    
    await _mealService.addMealEntry(meal);
    notifyListeners();
  }
  
  // Add a beverage with calories
  Future<void> logBeverage(String name, int calories, [double? volume]) async {
    await logMeal(name, calories);
  }
  
  // Determine meal type based on time of day
  String _determineMealType(TimeOfDay time) {
    final hour = time.hour;
    
    if (hour >= 5 && hour < 10) {
      return 'breakfast';
    } else if (hour >= 10 && hour < 14) {
      return 'lunch';
    } else if (hour >= 14 && hour < 18) {
      return 'snack';
    } else if (hour >= 18 && hour < 22) {
      return 'dinner';
    } else {
      return 'snack';
    }
  }
  
  // Get total calories for today
  int getTotalCaloriesForToday() {
    if (!_isInitialized) return 0;
    final today = DateTime.now();
    return _mealService.getTotalCaloriesForDay(today);
  }
  
  // Get calories by meal type for today
  Map<String, int> getCaloriesByMealTypeForToday() {
    if (!_isInitialized) return {'breakfast': 0, 'lunch': 0, 'dinner': 0, 'snack': 0};
    final today = DateTime.now();
    return _mealService.getCaloriesByMealTypeForDay(today);
  }
  
  // Get all meal entries for today
  List<MealEntry> getMealEntriesForToday() {
    if (!_isInitialized) return [];
    final today = DateTime.now();
    return _mealService.getMealEntriesForDay(today);
  }
} 