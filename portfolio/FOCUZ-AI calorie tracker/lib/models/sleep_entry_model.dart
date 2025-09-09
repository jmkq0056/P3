/// Model representing a sleep entry in the fitness app
class SleepEntryModel {
  final String id;
  final String userId;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final double? quality; // 0-10 scale
  final String? note;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? sleepData; // For additional sleep data (phases, etc.)

  SleepEntryModel({
    required this.id,
    required this.userId,
    required this.date,
    this.startTime,
    this.endTime,
    required this.durationMinutes,
    this.quality,
    this.note,
    required this.createdAt,
    this.updatedAt,
    this.sleepData,
  });

  /// Create a SleepEntryModel from a Map (e.g., from Firestore)
  factory SleepEntryModel.fromMap(Map<String, dynamic> map) {
    return SleepEntryModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      startTime: map['start_time'] != null ? DateTime.parse(map['start_time']) : null,
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      durationMinutes: map['duration_minutes'] ?? 0,
      quality: map['quality']?.toDouble(),
      note: map['note'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      sleepData: map['sleep_data'],
    );
  }

  /// Convert SleepEntryModel to a Map (e.g., for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String().split('T')[0], // Just the date part
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'quality': quality,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'sleep_data': sleepData,
    };
  }

  /// Create a copy of SleepEntryModel with some changes
  SleepEntryModel copyWith({
    String? id,
    String? userId,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    double? quality,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? sleepData,
  }) {
    return SleepEntryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      quality: quality ?? this.quality,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sleepData: sleepData ?? this.sleepData,
    );
  }
  
  /// Calculate the sleep quality rating as a string
  String get qualityRating {
    if (quality == null) return 'Not rated';
    if (quality! >= 8) return 'Excellent';
    if (quality! >= 6) return 'Good';
    if (quality! >= 4) return 'Fair';
    return 'Poor';
  }
  
  /// Get the formatted duration (e.g., "8h 30m")
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    return '${hours}h ${minutes}m';
  }
} 