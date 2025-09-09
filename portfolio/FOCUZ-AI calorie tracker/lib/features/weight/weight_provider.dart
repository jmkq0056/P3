import 'package:flutter/material.dart';
import '../../services/health_service.dart';
import '../../models/health_data.dart';

class WeightProvider extends InheritedWidget {
  final HealthService _healthService = HealthService();
  
  WeightProvider({
    super.key,
    required Widget child,
  }) : super(child: child) {
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    await _healthService.init();
  }
  
  static WeightProvider of(BuildContext context) {
    final WeightProvider? provider = context.dependOnInheritedWidgetOfExactType<WeightProvider>();
    assert(provider != null, 'No WeightProvider found in context');
    return provider!;
  }
  
  @override
  bool updateShouldNotify(WeightProvider oldWidget) {
    return false; // We don't need to notify in this simple implementation
  }
  
  // Log weight in kg
  Future<void> logWeight(double weightKg) async {
    final DateTime now = DateTime.now();
    final entry = WeightEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      weight: weightKg,
      date: now,
    );
    
    await _healthService.addWeightEntry(entry);
  }
  
  // Get all weight entries
  List<WeightEntry> getAllWeightEntries() {
    return _healthService.getAllWeightEntries();
  }
  
  // Get latest weight entry
  WeightEntry? getLatestWeightEntry() {
    final entries = getAllWeightEntries();
    if (entries.isEmpty) return null;
    
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries.first;
  }
} 