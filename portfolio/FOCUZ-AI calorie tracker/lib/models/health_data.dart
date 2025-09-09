import 'package:uuid/uuid.dart';

class WeightEntry {
  final String id;
  final DateTime date;
  final double weight;
  final String? note;

  WeightEntry({
    String? id,
    required this.date,
    required this.weight,
    this.note,
  }) : id = id ?? const Uuid().v4();
  
  // Convert to JSON for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weight': weight,
      'note': note,
    };
  }
  
  // Create from JSON (for SharedPreferences)
  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      weight: json['weight'] is int ? (json['weight'] as int).toDouble() : json['weight'],
      note: json['note'],
    );
  }
}

class WaterEntry {
  final String id;
  final DateTime date;
  final double amount; // in ml
  final String type; // water, coffee, tea, etc.

  WaterEntry({
    String? id,
    required this.date,
    required this.amount,
    required this.type,
  }) : id = id ?? const Uuid().v4();
  
  // Convert to JSON for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'type': type,
    };
  }
  
  // Create from JSON (for SharedPreferences)
  factory WaterEntry.fromJson(Map<String, dynamic> json) {
    return WaterEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      amount: json['amount'] is int ? (json['amount'] as int).toDouble() : json['amount'],
      type: json['type'],
    );
  }
}

class SleepEntry {
  final String id;
  final DateTime date;
  final DateTime bedTime;
  final DateTime wakeTime;
  final int quality; // 1-5 stars
  final String? note;

  SleepEntry({
    String? id,
    required this.date,
    required this.bedTime,
    required this.wakeTime,
    required this.quality,
    this.note,
  }) : id = id ?? const Uuid().v4();

  // Calculate sleep duration in hours
  double get durationInHours {
    final difference = wakeTime.difference(bedTime);
    return difference.inMinutes / 60.0;
  }
  
  // Convert to JSON for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'bedTime': bedTime.toIso8601String(),
      'wakeTime': wakeTime.toIso8601String(),
      'quality': quality,
      'note': note,
    };
  }
  
  // Create from JSON (for SharedPreferences)
  factory SleepEntry.fromJson(Map<String, dynamic> json) {
    return SleepEntry(
      id: json['id'],
      date: DateTime.parse(json['date']),
      bedTime: DateTime.parse(json['bedTime']),
      wakeTime: DateTime.parse(json['wakeTime']),
      quality: json['quality'],
      note: json['note'],
    );
  }
}

class TrainingStats {
  final int totalSessions;
  final int currentYearSessions;
  final int currentMonthSessions;
  final int currentWeekSessions;
  final double totalCaloriesBurned;
  final double totalHours;

  TrainingStats({
    this.totalSessions = 0,
    this.currentYearSessions = 0,
    this.currentMonthSessions = 0, 
    this.currentWeekSessions = 0,
    this.totalCaloriesBurned = 0,
    this.totalHours = 0,
  });
  
  // Convert to JSON for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'totalSessions': totalSessions,
      'currentYearSessions': currentYearSessions,
      'currentMonthSessions': currentMonthSessions,
      'currentWeekSessions': currentWeekSessions,
      'totalCaloriesBurned': totalCaloriesBurned,
      'totalHours': totalHours,
    };
  }
  
  // Create from JSON (for SharedPreferences)
  factory TrainingStats.fromJson(Map<String, dynamic> json) {
    return TrainingStats(
      totalSessions: json['totalSessions'] ?? 0,
      currentYearSessions: json['currentYearSessions'] ?? 0,
      currentMonthSessions: json['currentMonthSessions'] ?? 0,
      currentWeekSessions: json['currentWeekSessions'] ?? 0,
      totalCaloriesBurned: json['totalCaloriesBurned'] ?? 0,
      totalHours: json['totalHours'] ?? 0,
    );
  }
} 