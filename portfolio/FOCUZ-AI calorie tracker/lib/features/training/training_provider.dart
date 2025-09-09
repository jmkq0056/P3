import 'package:flutter/material.dart';
import '../../services/training_service.dart';
import '../../models/training.dart';

class TrainingProvider extends InheritedWidget {
  final TrainingService _trainingService = TrainingService();
  
  TrainingProvider({
    super.key,
    required Widget child,
  }) : super(child: child) {
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    await _trainingService.init();
  }
  
  static TrainingProvider of(BuildContext context) {
    final TrainingProvider? provider = context.dependOnInheritedWidgetOfExactType<TrainingProvider>();
    assert(provider != null, 'No TrainingProvider found in context');
    return provider!;
  }
  
  @override
  bool updateShouldNotify(TrainingProvider oldWidget) {
    return false;
  }
  
  // Log training session with type and duration in minutes
  Future<void> logTraining(String type, int durationMinutes) async {
    final DateTime now = DateTime.now();
    final int estimatedCalories = _estimateCaloriesBurned(type, durationMinutes);
    
    final entry = Training(
      title: "Quick $type workout",
      type: type,
      calories: estimatedCalories,
      date: now,
      duration: durationMinutes,
    );
    
    await _trainingService.addTraining(entry);
  }
  
  // Estimate calories burned based on activity type and duration
  int _estimateCaloriesBurned(String type, int durationMinutes) {
    // Simple estimation based on activity type
    final Map<String, int> caloriesPerMinute = {
      'running': 10,
      'jogging': 8,
      'walking': 4,
      'cycling': 7,
      'swimming': 9,
      'weight lifting': 6,
      'yoga': 3,
      'hiit': 12,
      'cardio': 8,
      'workout': 7,
    };
    
    final int calsPerMinute = caloriesPerMinute[type.toLowerCase()] ?? 5;
    return calsPerMinute * durationMinutes;
  }
} 