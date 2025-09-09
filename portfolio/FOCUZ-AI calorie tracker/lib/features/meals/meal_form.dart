import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/assets.dart';
import '../../core/constants.dart';
import '../../models/meal_data.dart' as models;
import '../../services/meal_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/ai_image_service.dart';

class MealFormScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onMealAdded;
  final Map<String, dynamic>? existingMeal;
  final bool isEditingCustomMeal;
  final DateTime? selectedDate;

  const MealFormScreen({
    super.key,
    this.onMealAdded,
    this.existingMeal,
    this.isEditingCustomMeal = false,
    this.selectedDate,
  });

  // Public method to update the meal form with AI analysis results
  static void updateFromAI(GlobalKey formKey, String name, int calories, 
      double protein, double fat, double carbs) {
    final state = formKey.currentState;
    if (state == null) return;
    
    // This uses runtime type checks to access the internal state
    try {
      // Convert to dynamic to access private members
      dynamic dynState = state;
      
      // Check if we have the correct state type
      if (dynState.toString().contains('_MealFormScreenState')) {
        dynState._nameController.text = name;
        dynState._caloriesController.text = calories.toString();
        
        // Calculate total calorie content from macros
        double proteinCalories = protein * 4;
        double carbsCalories = carbs * 4;
        double fatCalories = fat * 9;
        double totalCals = proteinCalories + carbsCalories + fatCalories;
        
        // Calculate percentages
        int proteinPercent = (proteinCalories / totalCals * 100).round();
        int carbsPercent = (carbsCalories / totalCals * 100).round();
        int fatPercent = (fatCalories / totalCals * 100).round();
        
        // Set percentage values ONLY
        dynState._proteinPercentController.text = proteinPercent.toString();
        dynState._carbsPercentController.text = carbsPercent.toString();
        dynState._fatPercentController.text = fatPercent.toString();
        
        // Set to use percentages and show macros section
        dynState._showMacros = true;
        dynState._usePercentages = true;
        
        // Grams will be automatically calculated from percentages when needed
        // So we don't need to set them explicitly
        
        // Show a popup with the calculated macro percentages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final scaffoldMessenger = ScaffoldMessenger.of(dynState.context);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Macros: $proteinPercent% protein, '
                  '$carbsPercent% carbs, '
                  '$fatPercent% fat'),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                onPressed: () => scaffoldMessenger.hideCurrentSnackBar(),
              ),
            ),
          );
        });
        
        // Rebuild the UI
        dynState.setState(() {});
        return;
      }
    } catch (e) {
      debugPrint('Could not update meal form: $e');
    }
  }

  @override
  State<MealFormScreen> createState() => _MealFormScreenState();
}

class _MealFormScreenState extends State<MealFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final MealService _mealService = MealService();
  final ImagePicker _imagePicker = ImagePicker();
  
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _portionController = TextEditingController();
  
  // Macro controllers for grams
  final _proteinController = TextEditingController(text: '0');
  final _carbsController = TextEditingController(text: '0');
  final _fatController = TextEditingController(text: '0');
  final _fiberController = TextEditingController(text: '0');
  
  // Macro controllers for percentages
  final _proteinPercentController = TextEditingController(text: '30');
  final _carbsPercentController = TextEditingController(text: '40');
  final _fatPercentController = TextEditingController(text: '30');
  
  String _selectedType = 'breakfast';
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  bool _showMacros = false;
  bool _usePercentages = true; // Default to using percentages
  bool _saveToMyMeals = false; // New flag for saving to custom meals
  bool _isLowFat = false; // New flag for Low Fat toggle
  String _dietType = 'Standard'; // New variable for Diet Type dropdown
  
  // Image upload variables - only show if no AI analysis was done
  File? _selectedImage;
  bool _isUploadingImage = false;
  String? _uploadedImageUrl;
  bool _hasAIAnalysis = false; // Track if this meal came from AI analysis
  
  // Add _macros property to fix the linter error
  models.Macros? _macros;
  
  // Diet types options
  final List<String> _dietTypes = ['Standard', 'Keto', 'Carnivore'];
  
  // Meal types options
  final List<Map<String, dynamic>> _mealTypes = [
    {'type': 'breakfast', 'name': 'Breakfast', 'icon': FontAwesomeIcons.bacon},
    {'type': 'lunch', 'name': 'Lunch', 'icon': FontAwesomeIcons.bowlRice},
    {'type': 'dinner', 'name': 'Dinner', 'icon': FontAwesomeIcons.drumstickBite},
    {'type': 'snack', 'name': 'Snack', 'icon': FontAwesomeIcons.appleWhole},
  ];
  
  // Mock search results for food database
  final List<Map<String, dynamic>> _searchResults = [
    {
      'name': 'Apple',
      'calories': 95,
      'portion': '1 medium',
      'macros': {'protein': 0.5, 'carbs': 25.0, 'fat': 0.3, 'fiber': 4.0}
    },
    {
      'name': 'Banana',
      'calories': 105,
      'portion': '1 medium',
      'macros': {'protein': 1.3, 'carbs': 27.0, 'fat': 0.4, 'fiber': 3.1}
    },
    {
      'name': 'Chicken Breast',
      'calories': 165,
      'portion': '100g',
      'macros': {'protein': 31.0, 'carbs': 0.0, 'fat': 3.6, 'fiber': 0.0}
    },
    {
      'name': 'Spinach Salad',
      'calories': 78,
      'portion': '100g',
      'macros': {'protein': 2.9, 'carbs': 3.6, 'fat': 0.4, 'fiber': 2.2}
    },
    {
      'name': 'Brown Rice',
      'calories': 215,
      'portion': '1 cup',
      'macros': {'protein': 5.0, 'carbs': 45.0, 'fat': 1.8, 'fiber': 3.5}
    },
    {
      'name': 'Egg',
      'calories': 70,
      'portion': '1 large',
      'macros': {'protein': 6.3, 'carbs': 0.4, 'fat': 5.0, 'fiber': 0.0}
    },
    {
      'name': 'Whole Wheat Bread',
      'calories': 80,
      'portion': '1 slice',
      'macros': {'protein': 4.0, 'carbs': 15.0, 'fat': 1.0, 'fiber': 2.0}
    },
    {
      'name': 'Avocado',
      'calories': 240,
      'portion': '1 whole',
      'macros': {'protein': 3.0, 'carbs': 12.0, 'fat': 22.0, 'fiber': 10.0}
    },
    {
      'name': 'Greek Yogurt',
      'calories': 100,
      'portion': '100g',
      'macros': {'protein': 10.0, 'carbs': 3.0, 'fat': 5.0, 'fiber': 0.0}
    },
    {
      'name': 'Salmon',
      'calories': 180,
      'portion': '100g',
      'macros': {'protein': 25.0, 'carbs': 0.0, 'fat': 8.0, 'fiber': 0.0}
    },
    {
      'name': 'Protein Shake',
      'calories': 120,
      'portion': '1 scoop',
      'macros': {'protein': 24.0, 'carbs': 3.0, 'fat': 1.0, 'fiber': 0.0}
    },
    {
      'name': 'Almonds',
      'calories': 160,
      'portion': '1/4 cup',
      'macros': {'protein': 6.0, 'carbs': 6.0, 'fat': 14.0, 'fiber': 3.5}
    },
  ];

  @override
  void initState() {
    super.initState();
    
    _initMealService();
    
    // Populate form if editing existing meal
    if (widget.existingMeal != null) {
      _nameController.text = widget.existingMeal!['name'];
      _caloriesController.text = widget.existingMeal!['calories'].toString();
      _selectedType = widget.existingMeal!['type'];
      _selectedTime = widget.existingMeal!['time'];
      
      if (widget.existingMeal!['portion'] != null) {
        _portionController.text = widget.existingMeal!['portion'];
      }
      
      if (widget.existingMeal!['macros'] != null) {
        _showMacros = true;
        _proteinController.text = widget.existingMeal!['macros']['protein'].toString();
        _carbsController.text = widget.existingMeal!['macros']['carbs'].toString();
        _fatController.text = widget.existingMeal!['macros']['fat'].toString();
        if (widget.existingMeal!['macros']['fiber'] != null) {
          _fiberController.text = widget.existingMeal!['macros']['fiber'].toString();
        }
        
        // Calculate and set percentages
        _updatePercentagesFromGrams();
      }
    }
  }
  
  Future<void> _initMealService() async {
    await _mealService.init();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _portionController.dispose();
    _searchController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _proteinPercentController.dispose();
    _carbsPercentController.dispose();
    _fatPercentController.dispose();
    super.dispose();
  }

  void _populateFieldsFromSearch(Map<String, dynamic> searchResult) {
    setState(() {
      _nameController.text = searchResult['name'];
      _caloriesController.text = searchResult['calories'].toString();
      _portionController.text = searchResult['portion'];
      
      if (searchResult['macros'] != null) {
        _showMacros = true;
        _proteinController.text = searchResult['macros']['protein'].toString();
        _carbsController.text = searchResult['macros']['carbs'].toString();
        _fatController.text = searchResult['macros']['fat'].toString();
        if (searchResult['macros']['fiber'] != null) {
          _fiberController.text = searchResult['macros']['fiber'].toString();
        }
        
        // Calculate percentages
        _updatePercentagesFromGrams();
      }
      
      _isSearching = false;
    });
  }
  
  // Calculate macro percentages from grams
  void _updatePercentagesFromGrams() {
    final proteinGrams = double.tryParse(_proteinController.text) ?? 0;
    final carbsGrams = double.tryParse(_carbsController.text) ?? 0;
    final fatGrams = double.tryParse(_fatController.text) ?? 0;
    
    final proteinCalories = proteinGrams * 4;
    final carbsCalories = carbsGrams * 4;
    final fatCalories = fatGrams * 9;
    
    final totalCalories = proteinCalories + carbsCalories + fatCalories;
    
    if (totalCalories > 0) {
      final proteinPercent = (proteinCalories / totalCalories * 100).round();
      final carbsPercent = (carbsCalories / totalCalories * 100).round();
      final fatPercent = (fatCalories / totalCalories * 100).round();
      
      _proteinPercentController.text = proteinPercent.toString();
      _carbsPercentController.text = carbsPercent.toString();
      _fatPercentController.text = fatPercent.toString();
    }
  }
  
  // Calculate grams from percentages and total calories
  void _updateGramsFromPercentages() {
    final calories = int.tryParse(_caloriesController.text) ?? 0;
    final proteinPercent = int.tryParse(_proteinPercentController.text) ?? 30;
    final carbsPercent = int.tryParse(_carbsPercentController.text) ?? 40;
    final fatPercent = int.tryParse(_fatPercentController.text) ?? 30;
    
    // Normalize percentages if they don't add up to 100
    final totalPercent = proteinPercent + carbsPercent + fatPercent;
    double normFactor = totalPercent > 0 ? 100 / totalPercent : 1;
    
    final proteinCalories = calories * (proteinPercent * normFactor) / 100;
    final carbsCalories = calories * (carbsPercent * normFactor) / 100;
    final fatCalories = calories * (fatPercent * normFactor) / 100;
    
    final proteinGrams = (proteinCalories / 4).round();
    final carbsGrams = (carbsCalories / 4).round();
    final fatGrams = (fatCalories / 9).round();
    
    _proteinController.text = proteinGrams.toString();
    _carbsController.text = carbsGrams.toString();
    _fatController.text = fatGrams.toString();
  }

  @override
  Widget build(BuildContext context) {
    return _isSearching ? _buildSearchView() : _buildAddMealForm();
  }

  Widget _buildAddMealForm() {
    final isEditing = widget.existingMeal != null;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.s16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search button
            
            const SizedBox(height: AppDimensions.s24),
            
            Text(
              'Meal Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppDimensions.s16),
            
            // Meal type selection
            Text(
              'Meal Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.s12),
            
            _buildMealTypeSelector(),
            const SizedBox(height: AppDimensions.s24),
            
            // Food name input
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Food Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.food_bank),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a food name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.s16),
            
            // Calories input
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Calories (kcal)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_fire_department),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter calories';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
              onChanged: (value) {
                if (_usePercentages && _showMacros) {
                  _updateGramsFromPercentages();
                }
              },
            ),
            const SizedBox(height: AppDimensions.s16),
            
            // New section for Low Fat toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Low Fat (under 10%)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Switch(
                  value: _isLowFat,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _isLowFat = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.s16),
            
            // New section for Diet Type dropdown
            Text(
              'Dietary Approach',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.s12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _dietType,
                  isExpanded: true,
                  items: _dietTypes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _dietType = value;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.s24),
            
            // Portion input
            TextFormField(
              controller: _portionController,
              decoration: const InputDecoration(
                labelText: 'Portion (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
                hintText: 'e.g., 1 cup, 100g, 1 piece',
              ),
            ),
            const SizedBox(height: AppDimensions.s16),
            
            // Macronutrients expander
            Card(
              margin: EdgeInsets.zero,
              child: ExpansionTile(
                initiallyExpanded: _showMacros,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _showMacros = expanded;
                    if (expanded && _usePercentages) {
                      _updateGramsFromPercentages();
                    }
                  });
                },
                title: const Text('Macronutrients'),
                leading: const Icon(Icons.pie_chart),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.s16),
                    child: Column(
                      children: [
                        // Toggle for grams vs percentages
                        SwitchListTile(
                          title: Text(_usePercentages ? 'Using Percentages' : 'Using Grams'),
                          subtitle: Text(_usePercentages 
                              ? 'Enter macros as percentages of total calories' 
                              : 'Enter macros in grams'),
                          value: _usePercentages,
                          onChanged: (value) {
                            setState(() {
                              _usePercentages = value;
                              if (value) {
                                _updatePercentagesFromGrams();
                              } else {
                                _updateGramsFromPercentages();
                              }
                            });
                          },
                        ),
                        const SizedBox(height: AppDimensions.s16),
                        
                        // Show either percentages or grams inputs
                        _usePercentages 
                            ? _buildMacroPercentInputs()
                            : _buildMacroGramInputs(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.s16),
            
            // Time selector
            InkWell(
              onTap: () => _selectTime(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Time',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                child: Text(
                  _formatTimeOfDay(_selectedTime),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.s16),
            
            // Image upload section - only show if no AI analysis was done
            if (!_hasAIAnalysis) 
              _buildImageUploadSection(),
            
            // Save to My Meals checkbox
            if (!widget.isEditingCustomMeal)
              CheckboxListTile(
                title: const Text('Save to My Meals'),
                subtitle: const Text('Add this meal to your custom meals collection for quick access later'),
                value: _saveToMyMeals,
                activeColor: AppColors.calories,
                onChanged: (value) {
                  setState(() {
                    _saveToMyMeals = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
            
            const SizedBox(height: AppDimensions.s32),
            
            // Save button
            ElevatedButton(
              onPressed: _saveMeal,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.calories,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: Text(isEditing ? 'Update Meal' : 'Add Meal'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget for macro inputs using percentages
  Widget _buildMacroPercentInputs() {
    return Column(
      children: [
        // Show a macro distribution bar
        LinearProgressIndicator(
          value: 1.0,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent),
          minHeight: 20,
        ),
        Stack(
          children: [
            // Stacked bars for visual representation of percentages
            Container(
              height: 20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: Colors.grey[300],
              ),
              margin: const EdgeInsets.only(bottom: 16),
            ),
            SizedBox(
              height: 20,
              child: Row(
                children: [
                  Flexible(
                    flex: int.tryParse(_proteinPercentController.text) ?? 30,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                        color: Colors.green,
                      ),
                    ),
                  ),
                  Flexible(
                    flex: int.tryParse(_carbsPercentController.text) ?? 40,
                    child: Container(
                      height: 20,
                      color: Colors.amber,
                    ),
                  ),
                  Flexible(
                    flex: int.tryParse(_fatPercentController.text) ?? 30,
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                        color: Colors.red.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        
        // Percent inputs
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _proteinPercentController,
                decoration: const InputDecoration(
                  labelText: 'Protein %',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  setState(() {
                    _updateGramsFromPercentages();
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _carbsPercentController,
                decoration: const InputDecoration(
                  labelText: 'Carbs %',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.grain),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  setState(() {
                    _updateGramsFromPercentages();
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _fatPercentController,
                decoration: const InputDecoration(
                  labelText: 'Fat %',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.opacity),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  setState(() {
                    _updateGramsFromPercentages();
                  });
                },
              ),
            ),
          ],
        ),
        
        // Display calculated grams
        const SizedBox(height: 16),
        Card(
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Protein', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${_proteinController.text}g',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Carbs', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${_carbsController.text}g',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Fat', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${_fatController.text}g',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        // Fiber input
        const SizedBox(height: 16),
        TextFormField(
          controller: _fiberController,
          decoration: const InputDecoration(
            labelText: 'Fiber (g)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.grass),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }
  
  // Widget for macro inputs using grams
  Widget _buildMacroGramInputs() {
    return Column(
      children: [
        // Protein input
        TextFormField(
          controller: _proteinController,
          decoration: const InputDecoration(
            labelText: 'Protein (g)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.fitness_center),
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) {
            _updatePercentagesFromGrams();
          },
        ),
        const SizedBox(height: AppDimensions.s16),
        
        // Carbs input
        TextFormField(
          controller: _carbsController,
          decoration: const InputDecoration(
            labelText: 'Carbs (g)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.grain),
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) {
            _updatePercentagesFromGrams();
          },
        ),
        const SizedBox(height: AppDimensions.s16),
        
        // Fat input
        TextFormField(
          controller: _fatController,
          decoration: const InputDecoration(
            labelText: 'Fat (g)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.opacity),
          ),
          keyboardType: TextInputType.number,
          onChanged: (_) {
            _updatePercentagesFromGrams();
          },
        ),
        const SizedBox(height: AppDimensions.s16),
        
        // Fiber input
        TextFormField(
          controller: _fiberController,
          decoration: const InputDecoration(
            labelText: 'Fiber (g)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.grass),
          ),
          keyboardType: TextInputType.number,
        ),
        
        // Display calculated percentages
        const SizedBox(height: 16),
        Card(
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Protein', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${_proteinPercentController.text}%',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Carbs', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${_carbsPercentController.text}%',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Fat', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${_fatPercentController.text}%',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _mealTypes.map((type) {
          final isSelected = _selectedType == type['type'];
          
          return Padding(
            padding: const EdgeInsets.only(right: AppDimensions.s12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedType = type['type'];
                });
              },
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              child: AnimatedContainer(
                duration: AppDurations.short,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.s16,
                  vertical: AppDimensions.s12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.calories
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.calories
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    FaIcon(
                      type['icon'],
                      size: AppDimensions.iconMedium,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    const SizedBox(width: AppDimensions.s8),
                    Text(
                      type['name'],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveMeal() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // Calculate total calories from macros if available and ensure consistent data
      if (_showMacros && _macros != null) {
        int calculatedCalories = (_macros!.proteinGrams * 4 + 
                             _macros!.carbsGrams * 4 + 
                             _macros!.fatGrams * 9).round();
        // If manual calories are significantly different from calculated, use calculated
        if ((int.tryParse(_caloriesController.text) ?? 0) < calculatedCalories * 0.8 ||
            (int.tryParse(_caloriesController.text) ?? 0) > calculatedCalories * 1.2) {
          _caloriesController.text = calculatedCalories.toString();
        }
      }
      
      // Upload image if selected or use AI uploaded image
      String? imageUrl = _uploadedImageUrl; // Use AI uploaded image if available
      if (_selectedImage != null && imageUrl == null) {
        imageUrl = await _uploadImageIfSelected();
        if (imageUrl == null) {
          // Image upload failed, but let user continue or retry
          final shouldContinue = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Image Upload Failed'),
              content: const Text('The image could not be uploaded. Would you like to save the meal without the image?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Save Without Image'),
                ),
              ],
            ),
          );
          
          if (shouldContinue != true) return;
        }
      }
      
      debugPrint('SAVING MEAL WITH IMAGE URL: $imageUrl');
      
      // Create macros object from the form inputs
      if (_showMacros) {
        _macros = models.Macros(
          proteinGrams: double.tryParse(_proteinController.text) ?? 0,
          carbsGrams: double.tryParse(_carbsController.text) ?? 0,
          fatGrams: double.tryParse(_fatController.text) ?? 0,
          fiberGrams: double.tryParse(_fiberController.text) ?? 0,
        );
      }
      
      // Build proper time of day
      // Get current time if no specific time selected
      final timeOfDay = models.TimeOfDay(
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
      );
      
      // Create meal entry
      final mealEntry = models.MealEntry(
        name: _nameController.text.trim(),
        calories: int.parse(_caloriesController.text),
        mealType: _selectedType,
        date: widget.selectedDate ?? DateTime.now(),
        portion: _portionController.text.trim(),
        timeOfDay: timeOfDay,
        macros: _macros,
        isLowFat: _isLowFat, // Include the new field
        dietType: _dietType, // Include the new field
        imageUrl: imageUrl, // Include the uploaded image URL
      );
      
      // Save to My Meals if checkbox is selected
      if (_saveToMyMeals && !widget.isEditingCustomMeal) {
        _saveAsCustomMeal(mealEntry);
      }
      
      // First show loading indicator 
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20, 
                height: 20, 
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
              ),
              SizedBox(width: 16),
              Text('Adding meal...'),
            ],
          ),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Ensure parent widget gets notified
      if (widget.onMealAdded != null) {
        try {
          // Use Future.delayed to let the UI update before proceeding
          Future.delayed(const Duration(milliseconds: 200), () {
            // Convert MealEntry to Map for the callback
            final mealMap = {
              'id': mealEntry.id,
              'name': mealEntry.name,
              'calories': mealEntry.calories,
              'type': mealEntry.mealType,
              'date': mealEntry.date,
              'portion': mealEntry.portion,
              'time': _selectedTime,
              'macros': _macros != null 
                ? {
                  'protein': _macros!.proteinGrams,
                  'carbs': _macros!.carbsGrams,
                  'fat': _macros!.fatGrams,
                  'fiber': _macros!.fiberGrams,
                }
                : null,
              'isLowFat': mealEntry.isLowFat,
              'dietType': mealEntry.dietType,
              'imageUrl': mealEntry.imageUrl, // Include the image URL
              'imageUrls': mealEntry.imageUrls, // Include multiple image URLs
              'hasImage': mealEntry.imageUrl != null || mealEntry.imageUrls.isNotEmpty,
            };
            
            // Debug log the meal data being passed
            debugPrint('MEAL FORM CALLBACK - Passing meal data:');
            debugPrint('- Name: ${mealMap['name']}');
            debugPrint('- Calories: ${mealMap['calories']}');
            debugPrint('- Image URL: ${mealMap['imageUrl']}');
            debugPrint('- Has Image: ${mealMap['hasImage']}');
            debugPrint('- Macros: ${mealMap['macros']}');
            debugPrint('- Is Low Fat: ${mealMap['isLowFat']}');
            debugPrint('- Diet Type: ${mealMap['dietType']}');
            
            // Call the callback with the meal map
            widget.onMealAdded!(mealMap);
          });
          
          // Separate message from the callback's own message
          Future.delayed(const Duration(milliseconds: 1500), () {
            messenger.showSnackBar(
              SnackBar(
                content: Text('${mealEntry.name} added from meal form'),
                backgroundColor: Colors.green,
              ),
            );
          });
        } catch (e) {
          debugPrint('ERROR calling onMealAdded: $e');
          // Show error that meal wasn't added
          messenger.showSnackBar(
            SnackBar(
              content: Text('Error: Could not add meal: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        debugPrint('WARNING: onMealAdded callback is null!');
        // Show error that meal wasn't added
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Error: Meal could not be added. No callback provided.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      // If in a screen with Navigator, pop back
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      }
    }
  }
  
  void _saveAsCustomMeal(models.MealEntry mealEntry) {
    // Create a CustomMeal from the MealEntry
    final customMeal = models.CustomMeal(
      name: mealEntry.name,
      calories: mealEntry.calories,
      mealType: mealEntry.mealType,
      portion: mealEntry.portion,
      macros: mealEntry.macros,
    );
    
    // Save to Hive
    _mealService.addCustomMeal(customMeal);
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Meal saved to My Meals'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  // Search view for food items
  Widget _buildSearchView() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(AppDimensions.s16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for a food',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppDimensions.s12,
                horizontal: AppDimensions.s16,
              ),
            ),
            onChanged: (value) {
              // In a real app, this would trigger a search API call
              setState(() {});
            },
          ),
        ),
        
        // Search results
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s16),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final result = _searchResults[index];
              final searchQuery = _searchController.text.toLowerCase();
              
              // Skip if doesn't match the search query
              if (searchQuery.isNotEmpty && 
                  !result['name'].toString().toLowerCase().contains(searchQuery)) {
                return const SizedBox.shrink();
              }
              
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.s8,
                  horizontal: AppDimensions.s16,
                ),
                title: Text(result['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${result['calories']} kcal | ${result['portion']}'),
                    if (result['macros'] != null)
                      Text(
                        'P: ${result['macros']['protein']}g | C: ${result['macros']['carbs']}g | F: ${result['macros']['fat']}g',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.calories.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: FaIcon(
                      AppAssets.iconMeals,
                      size: 20,
                      color: AppColors.calories,
                    ),
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: AppColors.calories,
                  onPressed: () {
                    _populateFieldsFromSearch(result);
                  },
                ),
                onTap: () {
                  _populateFieldsFromSearch(result);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Update form with AI analysis result
  void updateFromAIResult(String name, int calories, double protein, double fat, double carbs) {
    setState(() {
      _nameController.text = name;
      _caloriesController.text = calories.toString();
      _proteinController.text = protein.toString();
      _fatController.text = fat.toString();
      _carbsController.text = carbs.toString();
      _showMacros = true;
      _hasAIAnalysis = true; // Mark that this meal came from AI analysis
      
      // Calculate percentages from grams
      _updatePercentagesFromGrams();
    });
  }
  
  // Enhanced update from AI with comprehensive analysis result
  void updateFromEnhancedAIResult(FoodAnalysisResult result) {
    debugPrint('UPDATING MEAL FORM FROM ENHANCED AI RESULT:');
    debugPrint('- Food Name: ${result.foodName}');
    debugPrint('- Calories: ${result.calories}');
    debugPrint('- Image URL: ${result.imageUrl}');
    debugPrint('- Diet Type: ${result.dietType}');
    debugPrint('- Is Low Fat: ${result.isLowFat}');
    
    setState(() {
      _nameController.text = result.foodName;
      _caloriesController.text = result.calories.toString();
      _proteinController.text = result.protein.toString();
      _fatController.text = result.fat.toString();
      _carbsController.text = result.carbs.toString();
      _fiberController.text = result.fiber.toString();
      
      // Set diet preferences
      _isLowFat = result.isLowFat;
      _dietType = result.dietType;
      
      // Set image URL from AI analysis
      if (result.imageUrl != null) {
        _uploadedImageUrl = result.imageUrl;
        debugPrint('AI IMAGE URL SET: $_uploadedImageUrl');
      }
      
      // Set cooking method if detected
      if (result.cookingMethod != 'unknown') {
        // Could add cooking method field to meal form
      }
      
      // Set estimated weight if available
      if (result.estimatedWeight > 0) {
        // Could add weight field or use in portion description
        if (_portionController.text.isEmpty) {
          _portionController.text = '~${result.estimatedWeight.toInt()}g';
        }
      }
      
      // Set preparation notes from voice/text input
      if (result.voiceNotes?.isNotEmpty ?? false) {
        // Could add notes field to capture this
      }
      
      _showMacros = true;
      _hasAIAnalysis = true;
      
      // Create macros object immediately
      _macros = models.Macros(
        proteinGrams: result.protein,
        carbsGrams: result.carbs,
        fatGrams: result.fat,
        fiberGrams: result.fiber,
      );
      
      // Calculate percentages from grams
      _updatePercentagesFromGrams();
    });
  }

  // Build image upload section - only shows if no AI analysis was done
  Widget _buildImageUploadSection() {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meal Image (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.s12),
            
            if (_selectedImage != null) ...[
              // Show selected image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: AppDimensions.s12),
              
              // Remove image button
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _uploadedImageUrl = null;
                  });
                },
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Remove Image', style: TextStyle(color: Colors.red)),
              ),
            ] else ...[
              // Image picker buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingImage ? null : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.s12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingImage ? null : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('From Gallery'),
                    ),
                  ),
                ],
              ),
            ],
            
            if (_isUploadingImage)
              const Padding(
                padding: EdgeInsets.only(top: AppDimensions.s12),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _uploadedImageUrl = null; // Reset uploaded URL
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Upload image to Cloudinary when saving meal
  Future<String?> _uploadImageIfSelected() async {
    if (_selectedImage == null) return _uploadedImageUrl;
    
    setState(() {
      _isUploadingImage = true;
    });
    
    try {
      final cloudinaryService = CloudinaryService();
      final imageUrl = await cloudinaryService.uploadImage(_selectedImage!, imageType: 'meal');
      
      setState(() {
        _uploadedImageUrl = imageUrl;
        _isUploadingImage = false;
      });
      
      return imageUrl;
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading image: $e'),
          backgroundColor: Colors.red,
        ),
      );
      
      return null;
    }
  }
} 