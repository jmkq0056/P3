import 'package:uuid/uuid.dart';

class DailyMetrics {
  final String id;
  final DateTime date; // Only date, no time
  final int? steps;
  final double? waterIntake; // in ml
  final SleepData? sleepData;
  final double? weight; // in kg
  final Map<String, dynamic>? additionalMetrics; // For any other metrics
  final DateTime lastUpdated;

  DailyMetrics({
    String? id,
    required this.date,
    this.steps,
    this.waterIntake,
    this.sleepData,
    this.weight,
    this.additionalMetrics,
    DateTime? lastUpdated,
  }) : id = id ?? const Uuid().v4(),
       lastUpdated = lastUpdated ?? DateTime.now();

  // Get date key for ensuring uniqueness per day
  String get dateKey => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'steps': steps,
      'waterIntake': waterIntake,
      'sleepData': sleepData?.toJson(),
      'weight': weight,
      'additionalMetrics': additionalMetrics,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  // Create from JSON
  factory DailyMetrics.fromJson(Map<String, dynamic> json) {
    return DailyMetrics(
      id: json['id'],
      date: DateTime.parse(json['date']),
      steps: json['steps'],
      waterIntake: json['waterIntake']?.toDouble(),
      sleepData: json['sleepData'] != null ? SleepData.fromJson(json['sleepData']) : null,
      weight: json['weight']?.toDouble(),
      additionalMetrics: json['additionalMetrics'],
      lastUpdated: json['lastUpdated'] != null ? DateTime.parse(json['lastUpdated']) : DateTime.now(),
    );
  }

  // Create a copy with updated values
  DailyMetrics copyWith({
    String? id,
    DateTime? date,
    int? steps,
    double? waterIntake,
    SleepData? sleepData,
    double? weight,
    Map<String, dynamic>? additionalMetrics,
    DateTime? lastUpdated,
  }) {
    return DailyMetrics(
      id: id ?? this.id,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      waterIntake: waterIntake ?? this.waterIntake,
      sleepData: sleepData ?? this.sleepData,
      weight: weight ?? this.weight,
      additionalMetrics: additionalMetrics ?? this.additionalMetrics,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  // Merge with another daily metrics for the same day
  DailyMetrics mergeWith(DailyMetrics other) {
    if (dateKey != other.dateKey) {
      throw ArgumentError('Cannot merge daily metrics from different dates');
    }

    return DailyMetrics(
      id: id, // Keep original ID
      date: date,
      steps: other.steps ?? steps,
      waterIntake: other.waterIntake ?? waterIntake,
      sleepData: other.sleepData ?? sleepData,
      weight: other.weight ?? weight,
      additionalMetrics: {
        ...?additionalMetrics,
        ...?other.additionalMetrics,
      },
      lastUpdated: DateTime.now(),
    );
  }
}

class SleepData {
  final DateTime bedTime;
  final DateTime wakeTime;
  final int quality; // 1-5 rating
  final String? note;

  SleepData({
    required this.bedTime,
    required this.wakeTime,
    required this.quality,
    this.note,
  });

  // Calculate sleep duration in hours
  double get durationInHours {
    final difference = wakeTime.difference(bedTime);
    return difference.inMinutes / 60.0;
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'bedTime': bedTime.toIso8601String(),
      'wakeTime': wakeTime.toIso8601String(),
      'quality': quality,
      'note': note,
    };
  }

  // Create from JSON
  factory SleepData.fromJson(Map<String, dynamic> json) {
    return SleepData(
      bedTime: DateTime.parse(json['bedTime']),
      wakeTime: DateTime.parse(json['wakeTime']),
      quality: json['quality'],
      note: json['note'],
    );
  }

  // Create a copy with updated values
  SleepData copyWith({
    DateTime? bedTime,
    DateTime? wakeTime,
    int? quality,
    String? note,
  }) {
    return SleepData(
      bedTime: bedTime ?? this.bedTime,
      wakeTime: wakeTime ?? this.wakeTime,
      quality: quality ?? this.quality,
      note: note ?? this.note,
    );
  }
}

class WaterEntry {
  final String id;
  final DateTime timestamp;
  final double amount; // in ml
  final String type; // water, coffee, tea, etc.

  WaterEntry({
    String? id,
    required this.timestamp,
    required this.amount,
    required this.type,
  }) : id = id ?? const Uuid().v4();

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'amount': amount,
      'type': type,
    };
  }

  // Create from JSON
  factory WaterEntry.fromJson(Map<String, dynamic> json) {
    return WaterEntry(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      amount: json['amount']?.toDouble() ?? 0.0,
      type: json['type'],
    );
  }
} 