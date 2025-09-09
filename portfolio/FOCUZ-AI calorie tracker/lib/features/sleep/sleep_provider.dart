import 'package:flutter/material.dart';
import '../../services/health_service.dart';
import '../../models/health_data.dart';

class SleepProvider extends InheritedWidget {
  final HealthService _healthService = HealthService();
  
  SleepProvider({
    super.key,
    required Widget child,
  }) : super(child: child) {
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    await _healthService.init();
  }
  
  static SleepProvider of(BuildContext context) {
    final SleepProvider? provider = context.dependOnInheritedWidgetOfExactType<SleepProvider>();
    assert(provider != null, 'No SleepProvider found in context');
    return provider!;
  }
  
  @override
  bool updateShouldNotify(SleepProvider oldWidget) {
    return false; // We don't need to notify in this simple implementation
  }
  
  // Log sleep in hours with quality rating (1-5)
  Future<void> logSleep(double hours, int quality) async {
    final DateTime now = DateTime.now();
    final DateTime sleepEnd = now;
    final DateTime sleepStart = now.subtract(Duration(minutes: (hours * 60).round()));
    
    final entry = SleepEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: now,
      bedTime: sleepStart,
      wakeTime: sleepEnd,
      quality: quality,
      note: 'Added via voice command',
    );
    
    await _healthService.addSleepEntry(entry);
  }
  
  // Get all sleep entries
  List<SleepEntry> getAllSleepEntries() {
    return _healthService.getAllSleepEntries();
  }
  
  // Get latest sleep entry
  SleepEntry? getLatestSleepEntry() {
    return _healthService.getLatestSleepEntry();
  }
  
  // Get average sleep duration for the last week
  double getAverageSleepForLastWeek() {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final entries = _healthService.getSleepEntriesByDateRange(sevenDaysAgo, DateTime.now());
    
    if (entries.isEmpty) return 0;
    
    double totalHours = 0;
    for (final entry in entries) {
      totalHours += entry.durationInHours;
    }
    
    return totalHours / entries.length;
  }
} 