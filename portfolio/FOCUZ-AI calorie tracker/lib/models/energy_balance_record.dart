// Model for daily energy balance record used in the UI
class DailyEnergyRecord {
  final DateTime date;
  final int caloriesGoal;
  final int caloriesConsumed;
  final int walkingCalories;
  final int trainingCalories;
  final int calorieSurplusDeficit;

  DailyEnergyRecord({
    required this.date,
    required this.caloriesGoal,
    required this.caloriesConsumed,
    required this.walkingCalories,
    required this.trainingCalories,
    required this.calorieSurplusDeficit,
  });
}

// Model for storing energy balance records
class EnergyBalanceRecord {
  final DateTime date;
  final int caloriesGoal;
  final int caloriesConsumed;
  final int walkingCalories;
  final int trainingCalories;
  final int calorieSurplusDeficit;

  EnergyBalanceRecord({
    required this.date,
    required this.caloriesGoal,
    required this.caloriesConsumed,
    required this.walkingCalories,
    required this.trainingCalories,
    required this.calorieSurplusDeficit,
  });
  
  // Factory to create from DailyEnergyRecord
  factory EnergyBalanceRecord.fromDailyRecord(DailyEnergyRecord record) {
    return EnergyBalanceRecord(
      date: record.date,
      caloriesGoal: record.caloriesGoal,
      caloriesConsumed: record.caloriesConsumed,
      walkingCalories: record.walkingCalories,
      trainingCalories: record.trainingCalories,
      calorieSurplusDeficit: record.calorieSurplusDeficit,
    );
  }
  
  // Convert to DailyEnergyRecord
  DailyEnergyRecord toDailyRecord() {
    return DailyEnergyRecord(
      date: date,
      caloriesGoal: caloriesGoal,
      caloriesConsumed: caloriesConsumed,
      walkingCalories: walkingCalories,
      trainingCalories: trainingCalories,
      calorieSurplusDeficit: calorieSurplusDeficit,
    );
  }
  
  // Convert to JSON for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'caloriesGoal': caloriesGoal,
      'caloriesConsumed': caloriesConsumed,
      'walkingCalories': walkingCalories,
      'trainingCalories': trainingCalories,
      'calorieSurplusDeficit': calorieSurplusDeficit,
    };
  }
  
  // Factory to create from JSON
  factory EnergyBalanceRecord.fromJson(Map<String, dynamic> json) {
    return EnergyBalanceRecord(
      date: DateTime.parse(json['date']),
      caloriesGoal: json['caloriesGoal'],
      caloriesConsumed: json['caloriesConsumed'],
      walkingCalories: json['walkingCalories'],
      trainingCalories: json['trainingCalories'],
      calorieSurplusDeficit: json['calorieSurplusDeficit'],
    );
  }
} 