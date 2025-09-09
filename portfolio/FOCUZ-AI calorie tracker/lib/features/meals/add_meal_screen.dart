import 'package:flutter/material.dart';
import '../../models/meal_data.dart' as models;
import '../../services/meal_service.dart';

class AddMealScreen extends StatefulWidget {
  final DateTime? selectedDate;
  final Function(Map<String, dynamic>)? onMealAdded;

  const AddMealScreen({
    super.key,
    this.selectedDate,
    this.onMealAdded,
  });

  @override
  _AddMealScreenState createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final _formKey = GlobalKey<FormState>();
  final MealService _mealService = MealService();
  final TimeOfDay _selectedTime = TimeOfDay.now();
  
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _portionController = TextEditingController();
  
  models.Macros? _macros;
  bool _isCustomMeal = false;
  String _selectedMealType = 'breakfast';
  bool _showMacrosForm = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Meal'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ... (existing code)

                // Add macros form
                if (_showMacrosForm)
                  _buildMacrosForm(),
                
                const SizedBox(height: 20),
                
                const SizedBox(height: 40),
                
                // Save Button
                ElevatedButton(
                  onPressed: _saveMeal,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Save Meal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMacrosForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Macronutrients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        // Your macros form implementation would go here
        const Text('Macros form placeholder'),
      ],
    );
  }

  void _saveMeal() async {
    if (_formKey.currentState!.validate()) {
      // ... (existing code)
      
      // Create meal entry with new fields
      final meal = models.MealEntry(
        name: _nameController.text.trim(),
        calories: int.parse(_caloriesController.text),
        mealType: _selectedMealType,
        date: widget.selectedDate ?? DateTime.now(),
        portion: _portionController.text.trim(),
        timeOfDay: models.TimeOfDay(hour: _selectedTime.hour, minute: _selectedTime.minute),
        macros: _macros,
        // The isLowFat and dietType values will be set in the FoodImageAnalyzer
      );

      // Pass back to parent if callback exists
      if (widget.onMealAdded != null) {
        widget.onMealAdded!({
          'id': meal.id,
          'name': meal.name,
          'calories': meal.calories,
          'type': meal.mealType,
          'date': meal.date,
          'portion': meal.portion,
          'time': _selectedTime,
          'macros': _macros != null ? {
            'protein': _macros!.proteinGrams,
            'carbs': _macros!.carbsGrams,
            'fat': _macros!.fatGrams,
            'fiber': _macros!.fiberGrams,
          } : null,
          // The isLowFat and dietType fields will be handled in the FoodImageAnalyzer
        });
      }
      
      // Return to previous screen
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }
} 