import 'package:flutter/material.dart' as Flutter;
import 'package:uuid/uuid.dart';

class MealEntry {
  final String id;
  final DateTime date;
  final String name;
  final int calories;
  final String mealType; // breakfast, lunch, dinner, snack
  final String? portion;
  final Macros? macros;
  final TimeOfDay timeOfDay;
  final Map<String, dynamic>? additionalInfo;
  final bool isLowFat; // New field to indicate if food is under 10% fat
  final String dietType; // New field to store dietary approach
  final String? imageUrl; // New field to store Cloudinary image URL (primary image)
  final List<String> imageUrls; // New field to store multiple Cloudinary image URLs
  final double estimatedWeight; // Estimated weight in grams

  MealEntry({
    String? id,
    required this.date,
    required this.name,
    required this.calories,
    required this.mealType,
    required this.timeOfDay,
    this.portion,
    this.macros,
    this.additionalInfo,
    this.isLowFat = false, // Default to false
    this.dietType = 'Standard', // Default to 'Standard'
    this.imageUrl, // Optional image URL from Cloudinary (primary image)
    this.imageUrls = const [], // Multiple image URLs
    this.estimatedWeight = 0.0, // Estimated weight in grams
  }) : id = id ?? const Uuid().v4();
  
  // Convert to JSON for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'name': name,
      'calories': calories,
      'mealType': mealType,
      'portion': portion,
      'macros': macros?.toJson(),
      'timeOfDay': {
        'hour': timeOfDay.hour,
        'minute': timeOfDay.minute,
      },
      'additionalInfo': additionalInfo,
      'isLowFat': isLowFat, // Add to JSON
      'dietType': dietType, // Add to JSON
      'imageUrl': imageUrl, // Add to JSON
      'imageUrls': imageUrls, // Add multiple image URLs to JSON
      'estimatedWeight': estimatedWeight, // Add estimated weight to JSON
    };
  }
  
  // Create from JSON (for SharedPreferences)
  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      name: json['name'],
      calories: json['calories'],
      mealType: json['mealType'],
      portion: json['portion'],
      macros: json['macros'] != null ? Macros.fromJson(json['macros']) : null,
      timeOfDay: TimeOfDay(
        hour: json['timeOfDay']['hour'],
        minute: json['timeOfDay']['minute'],
      ),
      additionalInfo: json['additionalInfo'] as Map<String, dynamic>?,
      isLowFat: json['isLowFat'] as bool? ?? false, // Parse from JSON with default
      dietType: json['dietType'] as String? ?? 'Standard', // Parse from JSON with default
      imageUrl: json['imageUrl'] as String?, // Parse image URL from JSON
      imageUrls: json['imageUrls'] != null ? List<String>.from(json['imageUrls']) : const [], // Parse multiple image URLs
      estimatedWeight: json['estimatedWeight'] as double? ?? 0.0, // Parse estimated weight from JSON
    );
  }

  MealEntry copyWith({
    String? id,
    DateTime? date,
    String? name,
    int? calories,
    String? mealType,
    String? portion,
    Macros? macros,
    TimeOfDay? timeOfDay,
    Map<String, dynamic>? additionalInfo,
    bool? isLowFat,
    String? dietType,
    String? imageUrl,
    List<String>? imageUrls,
    double? estimatedWeight,
  }) {
    return MealEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      mealType: mealType ?? this.mealType,
      portion: portion ?? this.portion,
      macros: macros ?? this.macros,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      isLowFat: isLowFat ?? this.isLowFat,
      dietType: dietType ?? this.dietType,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      estimatedWeight: estimatedWeight ?? this.estimatedWeight,
    );
  }
}

class CustomMeal {
  final String id;
  final String name;
  final int calories;
  final String? portion;
  final Macros? macros;
  final String mealType; // Default meal type (breakfast, lunch, dinner, snack)

  CustomMeal({
    String? id,
    required this.name,
    required this.calories,
    required this.mealType,
    this.portion,
    this.macros,
  }) : id = id ?? const Uuid().v4();
  
  // Convert to JSON for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'mealType': mealType,
      'portion': portion,
      'macros': macros?.toJson(),
    };
  }
  
  // Create from JSON (for SharedPreferences)
  factory CustomMeal.fromJson(Map<String, dynamic> json) {
    return CustomMeal(
      id: json['id'],
      name: json['name'],
      calories: json['calories'],
      mealType: json['mealType'],
      portion: json['portion'],
      macros: json['macros'] != null ? Macros.fromJson(json['macros']) : null,
    );
  }
  
  // Create a MealEntry from this CustomMeal
  MealEntry toMealEntry({
    required DateTime date,
    required TimeOfDay timeOfDay,
    int? customCalories,
    String? customPortion,
    String? customMealType,
  }) {
    return MealEntry(
      date: date,
      name: name,
      calories: customCalories ?? calories,
      mealType: customMealType ?? mealType,
      timeOfDay: timeOfDay,
      portion: customPortion ?? portion,
      macros: macros != null && customCalories != null
          ? _adjustMacrosForCalories(macros!, calories, customCalories)
          : macros,
    );
  }
  
  // Helper to adjust macros proportionally when calories change
  Macros _adjustMacrosForCalories(Macros originalMacros, int originalCalories, int newCalories) {
    if (originalCalories <= 0 || newCalories <= 0) return originalMacros;
    
    final ratio = newCalories / originalCalories;
    
    return Macros(
      proteinGrams: originalMacros.proteinGrams * ratio,
      carbsGrams: originalMacros.carbsGrams * ratio,
      fatGrams: originalMacros.fatGrams * ratio,
      fiberGrams: originalMacros.fiberGrams != null 
          ? originalMacros.fiberGrams! * ratio 
          : null,
    );
  }
}

class Macros {
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double? fiberGrams;

  Macros({
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.fiberGrams,
  });
  
  // Convert to JSON for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'proteinGrams': proteinGrams,
      'carbsGrams': carbsGrams,
      'fatGrams': fatGrams,
      'fiberGrams': fiberGrams,
    };
  }
  
  // Create from JSON (for SharedPreferences)
  factory Macros.fromJson(Map<String, dynamic> json) {
    return Macros(
      proteinGrams: json['proteinGrams'],
      carbsGrams: json['carbsGrams'],
      fatGrams: json['fatGrams'],
      fiberGrams: json['fiberGrams'],
    );
  }

  // Calculate macronutrient percentages
  double get proteinPercentage {
    final totalCalories = (proteinGrams * 4) + (carbsGrams * 4) + (fatGrams * 9);
    return totalCalories <= 0 ? 0 : (proteinGrams * 4) / totalCalories;
  }
  
  double get carbsPercentage {
    final totalCalories = (proteinGrams * 4) + (carbsGrams * 4) + (fatGrams * 9);
    return totalCalories <= 0 ? 0 : (carbsGrams * 4) / totalCalories;
  }
  
  double get fatPercentage {
    final totalCalories = (proteinGrams * 4) + (carbsGrams * 4) + (fatGrams * 9);
    return totalCalories <= 0 ? 0 : (fatGrams * 9) / totalCalories;
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({
    required this.hour,
    required this.minute,
  });

  // Factory to create from Flutter's TimeOfDay
  factory TimeOfDay.fromFlutterTimeOfDay(Flutter.TimeOfDay time) {
    return TimeOfDay(hour: time.hour, minute: time.minute);
  }

  // Convert to Flutter's TimeOfDay
  Flutter.TimeOfDay toFlutterTimeOfDay() {
    return Flutter.TimeOfDay(hour: hour, minute: minute);
  }
  
  // To JSON helper
  Map<String, dynamic> toJson() {
    return {
      'hour': hour,
      'minute': minute,
    };
  }
  
  // From JSON helper
  factory TimeOfDay.fromJson(Map<String, dynamic> json) {
    return TimeOfDay(
      hour: json['hour'],
      minute: json['minute'],
    );
  }
}

// Nutrition profile for users to track calorie goals
class NutritionProfile {
  final String id;
  final double heightCm;
  final double weight;
  final int age;
  final String gender; // 'male' or 'female'
  final String activityLevel; // 'sedentary', 'light', 'moderate', 'active', 'very_active'
  final String goal; // 'lose', 'maintain', 'gain'
  final int customCalorieGoal; // If set manually
  final double? strideLengthMeters; // User's manually set stride length (optional)

  NutritionProfile({
    String? id,
    required this.heightCm,
    required this.weight,
    required this.age,
    required this.gender,
    required this.activityLevel,
    required this.goal,
    this.customCalorieGoal = 0,
    this.strideLengthMeters,
  }) : id = id ?? const Uuid().v4();
  
  // Convert to JSON for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'heightCm': heightCm,
      'weight': weight,
      'age': age,
      'gender': gender,
      'activityLevel': activityLevel,
      'goal': goal,
      'customCalorieGoal': customCalorieGoal,
      'strideLengthMeters': strideLengthMeters,
    };
  }
  
  // Create from JSON (for SharedPreferences)
  factory NutritionProfile.fromJson(Map<String, dynamic> json) {
    return NutritionProfile(
      id: json['id'],
      heightCm: json['heightCm'],
      weight: json['weight'],
      age: json['age'],
      gender: json['gender'],
      activityLevel: json['activityLevel'],
      goal: json['goal'],
      customCalorieGoal: json['customCalorieGoal'] ?? 0,
      strideLengthMeters: json['strideLengthMeters'],
    );
  }
  
  // Calculate Basal Metabolic Rate (BMR) using Mifflin-St Jeor Equation
  int calculateBMR() {
    if (gender == 'male') {
      return (10 * weight + 6.25 * heightCm - 5 * age + 5).round();
    } else {
      return (10 * weight + 6.25 * heightCm - 5 * age - 161).round();
    }
  }
  
  // Calculate target calories based on goal
  int calculateTargetCalories() {
    if (customCalorieGoal > 0) {
      return customCalorieGoal;
    }
    
    final bmr = calculateBMR();
    
    switch (goal) {
      case 'lose':
        return (bmr * 0.8).round(); // 20% deficit
      case 'maintain':
        return bmr;
      case 'gain':
        return (bmr * 1.15).round(); // 15% surplus
      default:
        return bmr;
    }
  }
  
  // Calculate macronutrient targets based on goal
  Macros calculateMacroTargets() {
    final targetCalories = calculateTargetCalories();
    
    double proteinPercentage, carbsPercentage, fatPercentage;
    
    switch (goal) {
      case 'lose':
        proteinPercentage = 0.35; // 35% protein
        fatPercentage = 0.3;    // 30% fat
        carbsPercentage = 0.35;  // 35% carbs
        break;
      case 'maintain':
        proteinPercentage = 0.3;  // 30% protein
        fatPercentage = 0.3;    // 30% fat
        carbsPercentage = 0.4;  // 40% carbs
        break;
      case 'gain':
        proteinPercentage = 0.25; // 25% protein
        fatPercentage = 0.25;   // 25% fat
        carbsPercentage = 0.5;  // 50% carbs
        break;
      default:
        proteinPercentage = 0.3;
        fatPercentage = 0.3;
        carbsPercentage = 0.4;
    }
    
    // Calculate grams based on percentages and calorie totals
    final proteinCalories = targetCalories * proteinPercentage;
    final carbsCalories = targetCalories * carbsPercentage;
    final fatCalories = targetCalories * fatPercentage;
    
    // Convert calories to grams (protein: 4 cal/g, carbs: 4 cal/g, fat: 9 cal/g)
    final proteinGrams = proteinCalories / 4;
    final carbsGrams = carbsCalories / 4;
    final fatGrams = fatCalories / 9;
    
    return Macros(
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
      fiberGrams: carbsGrams * 0.1, // Rough estimate: 10% of carbs as fiber
    );
  }
} 