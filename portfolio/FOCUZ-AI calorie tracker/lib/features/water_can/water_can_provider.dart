import 'package:flutter/material.dart';
import '../../services/health_service.dart';
import '../../models/health_data.dart';

class WaterCanProvider extends InheritedWidget {
  final HealthService _healthService = HealthService();
  
  WaterCanProvider({
    super.key,
    required Widget child,
  }) : super(child: child) {
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    await _healthService.init();
  }
  
  static WaterCanProvider of(BuildContext context) {
    final WaterCanProvider? provider = context.dependOnInheritedWidgetOfExactType<WaterCanProvider>();
    assert(provider != null, 'No WaterCanProvider found in context');
    return provider!;
  }
  
  @override
  bool updateShouldNotify(WaterCanProvider oldWidget) {
    return false; // We don't need to notify in this simple implementation
  }
  
  // Add water in milliliters
  Future<void> addWater(int amountMl) async {
    final DateTime now = DateTime.now();
    await _healthService.addWaterEntry(
      WaterEntry(
        date: now,
        amount: amountMl.toDouble(),
        type: 'water',
      ),
    );
  }
  
  // Add beverage in milliliters
  Future<void> addBeverage(String name, int amountMl) async {
    final DateTime now = DateTime.now();
    await _healthService.addWaterEntry(
      WaterEntry(
        date: now,
        amount: amountMl.toDouble(),
        type: name,
      ),
    );
  }
  
  // Get total water for today
  int getTotalWaterForToday() {
    final DateTime today = DateTime.now();
    return _healthService.getTotalWaterForDay(today).toInt();
  }
} 