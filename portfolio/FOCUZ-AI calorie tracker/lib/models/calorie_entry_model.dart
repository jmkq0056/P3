/// Model representing a calorie/meal entry in the fitness app
class CalorieEntryModel {
  final String id;
  final String userId;
  final DateTime date;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  final String? foodName;
  final int calories;
  final double? protein; // in grams
  final double? carbs; // in grams
  final double? fat; // in grams
  final String? photoUrl;
  final String? note;
  final Map<String, dynamic>? nutritionData; // Additional nutrition data
  final DateTime createdAt;
  final DateTime? updatedAt;

  CalorieEntryModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealType,
    this.foodName,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.photoUrl,
    this.note,
    this.nutritionData,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create a CalorieEntryModel from a Map (e.g., from Firestore)
  factory CalorieEntryModel.fromMap(Map<String, dynamic> map) {
    return CalorieEntryModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      mealType: map['meal_type'] ?? 'snack',
      foodName: map['food_name'],
      calories: map['calories'] ?? 0,
      protein: map['protein']?.toDouble(),
      carbs: map['carbs']?.toDouble(),
      fat: map['fat']?.toDouble(),
      photoUrl: map['photo_url'],
      note: map['note'],
      nutritionData: map['nutrition_data'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  /// Convert CalorieEntryModel to a Map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0], // Just the date part
      'meal_type': mealType,
      'food_name': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'photo_url': photoUrl,
      'note': note,
      'nutrition_data': nutritionData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create a copy of CalorieEntryModel with some changes
  CalorieEntryModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? mealType,
    String? foodName,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? photoUrl,
    String? note,
    Map<String, dynamic>? nutritionData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalorieEntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      photoUrl: photoUrl ?? this.photoUrl,
      note: note ?? this.note,
      nutritionData: nutritionData ?? this.nutritionData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// Get the capitalized meal type
  String get capitalizedMealType {
    return mealType.substring(0, 1).toUpperCase() + mealType.substring(1);
  }
  
  /// Get a summary of the meal
  String get summary {
    final name = foodName ?? 'Meal';
    return '$name ($calories cal)';
  }
  
  /// Get macronutrient breakdown as a formatted string
  String get macroBreakdown {
    if (protein == null || carbs == null || fat == null) {
      return 'Macros not available';
    }
    return 'P: ${protein!.toInt()}g · C: ${carbs!.toInt()}g · F: ${fat!.toInt()}g';
  }
} 