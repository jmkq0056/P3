import 'package:uuid/uuid.dart';

class Training {
  final String id;
  String title;
  DateTime date;
  int calories;
  int duration;
  String type;
  String? videoUrl; // Cloudinary URL for training video

  Training({
    String? id,
    required this.title,
    required this.date,
    required this.calories,
    required this.duration,
    required this.type,
    this.videoUrl,
  }) : id = id ?? const Uuid().v4();

  // Create a copy with potentially new values
  Training copyWith({
    String? title,
    DateTime? date,
    int? calories,
    int? duration,
    String? type,
    String? videoUrl,
  }) {
    return Training(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      calories: calories ?? this.calories,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  // Convert from a map (used when editing from form)
  factory Training.fromMap(Map<String, dynamic> map) {
    return Training(
      id: map['id'],
      title: map['title'],
      date: map['date'],
      calories: map['calories'],
      duration: map['duration'],
      type: map['type'],
      videoUrl: map['videoUrl'],
    );
  }

  // Convert to a map (used for UI display)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'calories': calories,
      'duration': duration,
      'type': type,
      'videoUrl': videoUrl,
    };
  }
  
  // Convert to JSON for SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'calories': calories,
      'duration': duration,
      'type': type,
      'videoUrl': videoUrl,
    };
  }
  
  // Create from JSON (for SharedPreferences)
  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      id: json['id'],
      title: json['title'],
      date: DateTime.parse(json['date']),
      calories: json['calories'],
      duration: json['duration'],
      type: json['type'],
      videoUrl: json['videoUrl'],
    );
  }
}

// This class will be auto-generated after running build_runner
// Generated adapter: TrainingAdapter 