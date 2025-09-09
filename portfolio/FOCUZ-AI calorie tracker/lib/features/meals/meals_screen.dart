import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as flutter show TimeOfDay;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import '../../core/assets.dart';
import '../../core/constants.dart';
import '../../widgets/animated_progress.dart';
import '../../widgets/food_image_analyzer.dart';
import '../../widgets/meal_nutrition_dialog.dart';
import '../../services/meal_service.dart';
import '../../services/ai_image_service.dart';
import '../../models/meal_data.dart';
import '../../models/meal_data.dart' as models;
import '../dashboard/dashboard_screen.dart'; // Import to access AppState
import 'meal_form.dart';
import '../../widgets/custom_app_bar.dart';

class MealsScreen extends StatefulWidget {
  final DateTime? selectedDate;
  
  const MealsScreen({Key? key, this.selectedDate}) : super(key: key);

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MealService _mealService = MealService();
  final AppState _appState = AppState(); // Add reference to global app state
  bool _isLoading = true;
  
  // Caloric info
  final Map<String, dynamic> _caloricInfo = {
    'consumed': 0,
    'goal': 2000,
    'breakfast': 0,
    'lunch': 0,
    'dinner': 0,
    'snacks': 0,
  };
  
  // Meals data
  List<Map<String, dynamic>> _todayMeals = [];
  List<CustomMeal> _customMeals = [];
  Map<String, List<CustomMeal>> _customMealsByType = {};
  Map<String, double> _macroPercentages = {
    'protein': 0.3,
    'carbs': 0.5,
    'fat': 0.2,
  };
  
  // Reference to the meal form
  final mealFormKey = GlobalKey();
  
  // Animation controllers
  final List<GlobalKey<AnimatedListState>> _listKeys = [
    GlobalKey<AnimatedListState>(), // breakfast
    GlobalKey<AnimatedListState>(), // lunch
    GlobalKey<AnimatedListState>(), // dinner
    GlobalKey<AnimatedListState>(), // snack
  ];

  // Date being displayed (defaults to today if not provided)
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedDate = widget.selectedDate ?? DateTime.now();
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _mealService.init();
      await _loadMeals();
    } catch (e) {
      debugPrint('Error initializing meal service: $e');
      
      // Display error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading meal data: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadMeals() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get the meal entries for the selected date, with detailed logging
      debugPrint('LOADING MEALS FOR DATE: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}');
      List<MealEntry> mealEntries = [];
      
      try {
        mealEntries = _mealService.getMealEntriesForDay(_selectedDate);
        debugPrint('LOADED ${mealEntries.length} MEAL ENTRIES');
      } catch (e) {
        debugPrint('Error loading meals for day: $e');
        mealEntries = []; // Ensure this is empty if error occurs
      }
      
      // Convert MealEntry objects to the format used by UI
      final meals = <Map<String, dynamic>>[];
      
      for (final entry in mealEntries) {
        try {
          final flutterTimeOfDay = entry.timeOfDay.toFlutterTimeOfDay();
          
          final meal = {
            'id': entry.id,
            'name': entry.name,
            'calories': entry.calories,
            'type': entry.mealType,
            'time': flutterTimeOfDay,
            'image': null,
            'portion': entry.portion,
            // Include image data - check both imageUrl and imageUrls
            'imageUrl': entry.imageUrl, // Single image URL
            'imageUrls': entry.imageUrls, // Multiple image URLs
            'hasImage': entry.imageUrl != null || entry.imageUrls.isNotEmpty,
          };
          
          if (entry.macros != null) {
            meal['macros'] = {
              'protein': entry.macros!.proteinGrams,
              'carbs': entry.macros!.carbsGrams,
              'fat': entry.macros!.fatGrams,
              'fiber': entry.macros!.fiberGrams,
            };
          }
          
          meals.add(meal);
        } catch (e) {
          debugPrint('Error processing meal entry: $e');
        }
      }
      
      // Calculate total calories - use safer approach to avoid errors
      int totalCalories = 0;
      try {
        totalCalories = _mealService.getTotalCaloriesForDay(_selectedDate);
      } catch (e) {
        debugPrint('Error getting total calories: $e');
      }
      
      // Get target calories from nutrition profile
      int targetCalories = 2000; // Default
      try {
        final nutritionProfile = _mealService.getNutritionProfile();
        if (nutritionProfile != null) {
          targetCalories = nutritionProfile.calculateTargetCalories();
        }
      } catch (e) {
        debugPrint('Error getting nutrition profile: $e');
      }
      
      // Calculate calories by meal type with safer approach
      Map<String, int> caloriesByType = {
        'breakfast': 0,
        'lunch': 0,
        'dinner': 0,
        'snack': 0,
      };
      
      // Manual calculation if needed
      if (mealEntries.isNotEmpty) {
        for (final entry in mealEntries) {
          caloriesByType[entry.mealType] = (caloriesByType[entry.mealType] ?? 0) + entry.calories;
        }
      } else {
        try {
          caloriesByType = _mealService.getCaloriesByMealTypeForDay(_selectedDate);
        } catch (e) {
          debugPrint('Error getting calories by type: $e');
        }
      }
      
      // Load custom meals
      List<CustomMeal> customMeals = [];
      try {
        customMeals = _mealService.getAllCustomMeals();
      } catch (e) {
        debugPrint('Error loading custom meals: $e');
      }
      
      // Calculate macro percentages
      Macros totalMacros = _mealService.getTotalMacrosForDay(_selectedDate);
      Map<String, double> macroPercentages = {
        'protein': totalMacros.proteinPercentage,
        'carbs': totalMacros.carbsPercentage,
        'fat': totalMacros.fatPercentage,
      };
      
      setState(() {
        _todayMeals = meals;
        _caloricInfo['consumed'] = totalCalories;
        _caloricInfo['goal'] = targetCalories;
        _caloricInfo['breakfast'] = caloriesByType['breakfast'] ?? 0;
        _caloricInfo['lunch'] = caloriesByType['lunch'] ?? 0;
        _caloricInfo['dinner'] = caloriesByType['dinner'] ?? 0;
        _caloricInfo['snacks'] = caloriesByType['snack'] ?? 0;
        _customMeals = customMeals;
        _customMealsByType = _mealService.getCustomMealsByType();
        _macroPercentages = macroPercentages;
        _isLoading = false;
      });
      
      // Log debug info about current meals
      debugPrint('MEALS LOADED: ${_todayMeals.length} meals, ${_caloricInfo['consumed']} calories consumed');
    } catch (e) {
      debugPrint('CRITICAL ERROR in _loadMeals: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading meals: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadMeals,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Meals & Nutrition',
        icon: AppAssets.iconCalendar,
        onIconPressed: () {
          // Show calendar
        },
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Add Meal'),
            Tab(text: 'My Meals'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Today's meals tab
                _buildTodayTab(),
                
                // Add meal tab
                SingleChildScrollView(
                  child: Column(
                    children: [
                      // Food Image Analyzer
                      FoodImageAnalyzer(
                        onAnalysisResult: (result) {
                          _fillMealFormFromAnalysis(result);
                        },
                      ),
                      
                      // Manual Meal Form
                      MealFormScreen(
                        key: mealFormKey,
                        selectedDate: _selectedDate,
                        onMealAdded: (meal) async {
                          try {
                            debugPrint('MEAL FORM CALLBACK TRIGGERED - Adding meal: ${meal['name']}');
                            
                            // METHOD 1: Convert to MealEntry and save
                            final entry = _createMealEntry(meal);
                            
                            // METHOD 2: Double-check the meal entry was created properly
                            if (entry.name.isEmpty || entry.calories <= 0) {
                              throw Exception('Invalid meal data: name or calories missing');
                            }
                            
                            // METHOD 3: Save with direct reference to meal service to avoid any context issues
                            final mealService = MealService();
                            await mealService.init();  // Ensure it's initialized
                            await mealService.addMealEntry(entry);
                            
                            // METHOD 4: Verify the entry was actually saved
                            final allEntries = mealService.getAllMealEntries();
                            final savedEntry = allEntries.any((e) => e.id == entry.id);
                            
                            if (!savedEntry) {
                              debugPrint('WARNING: Could not verify meal was saved! Trying alternative method...');
                              
                              // METHOD 5: Try alternative saving method
                              final newEntry = MealEntry(
                                date: _selectedDate,
                                name: meal['name'],
                                calories: meal['calories'],
                                mealType: meal['type'],
                                timeOfDay: models.TimeOfDay(
                                  hour: (meal['time'] as flutter.TimeOfDay).hour,
                                  minute: (meal['time'] as flutter.TimeOfDay).minute
                                ),
                                portion: meal['portion'],
                              );
                              await mealService.addMealEntry(newEntry);
                            }
                            
                            // METHOD 6: Reload data with delay to ensure DB operations complete
                            await Future.delayed(const Duration(milliseconds: 300));
                            await _loadMeals();
                            
                            // METHOD 7: Update UI and state
                            _appState.notifyDataChanged(); 
                            _tabController.animateTo(0); // Switch back to Today tab
                            
                            // Show success toast
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${meal['name']} successfully added to ${_selectedDate.day == DateTime.now().day ? "today's" : "selected date's"} meals'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            
                            debugPrint('MEAL ADDED SUCCESSFULLY: ${entry.id}');
                          } catch (e) {
                            debugPrint('ERROR ADDING MEAL: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error adding meal: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 5),
                                action: SnackBarAction(
                                  label: 'Retry',
                                  onPressed: () {
                                    // Try again with the same meal data
                                    _createAndSaveMeal(meal);
                                  },
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                
                // Custom meals tab
                _buildCustomMealsTab(),
              ],
            ),
    );
  }
  
  // Create a MealEntry from a meal map
  MealEntry _createMealEntry(Map<String, dynamic> meal) {
    // First get the Flutter.TimeOfDay from the meal
    final flutterTimeOfDay = meal['time'] as flutter.TimeOfDay;
    
    // Convert to our custom TimeOfDay using the factory method
    final timeOfDay = models.TimeOfDay(
      hour: flutterTimeOfDay.hour,
      minute: flutterTimeOfDay.minute
    );
    
    models.Macros? macros;
    if (meal['macros'] != null) {
      macros = models.Macros(
        proteinGrams: (meal['macros']['protein'] ?? 0.0).toDouble(),
        carbsGrams: (meal['macros']['carbs'] ?? 0.0).toDouble(),
        fatGrams: (meal['macros']['fat'] ?? 0.0).toDouble(),
        fiberGrams: (meal['macros']['fiber'] ?? 0.0).toDouble(),
      );
    }
    
    // Use the selectedDate from widget or current date
    final mealDate = _selectedDate;
    
    debugPrint('Creating MealEntry:');
    debugPrint('- Date: $mealDate');
    debugPrint('- Name: ${meal['name']}');
    debugPrint('- Calories: ${meal['calories']}');
    debugPrint('- Type: ${meal['type']}');
    debugPrint('- Time: ${flutterTimeOfDay.hour}:${flutterTimeOfDay.minute}');
    
    debugPrint('CREATING MEAL ENTRY WITH:');
    debugPrint('- Image URL: ${meal['imageUrl']}');
    debugPrint('- Has Image: ${meal['hasImage']}');
    debugPrint('- Macros: ${meal['macros']}');
    debugPrint('- Is Low Fat: ${meal['isLowFat']}');
    debugPrint('- Diet Type: ${meal['dietType']}');

    return MealEntry(
      date: mealDate,
      name: meal['name'],
      calories: meal['calories'],
      mealType: meal['type'],
      timeOfDay: timeOfDay,  // Our custom TimeOfDay type
      portion: meal['portion'],
      macros: macros,
      imageUrl: meal['imageUrl'], // Include single image URL
      imageUrls: meal['imageUrls'] != null ? List<String>.from(meal['imageUrls']) : [], // Include multiple image URLs
      isLowFat: meal['isLowFat'] ?? false, // Include isLowFat flag
      dietType: meal['dietType'] ?? 'Standard', // Include diet type
    );
  }

  Widget _buildTodayTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calorie summary card
          _buildCalorieCard(),
          const SizedBox(height: AppDimensions.s32),
          
          // Meals today
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedDate.year == DateTime.now().year && 
                _selectedDate.month == DateTime.now().month && 
                _selectedDate.day == DateTime.now().day 
                ? 'Today\'s Meals' 
                : 'Meals for ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Row(
                children: [
                  // Direct add button
                  ElevatedButton.icon(
                    icon: FaIcon(
                      FontAwesomeIcons.utensils,
                      size: AppDimensions.iconSmall,
                    ),
                    label: const Text('Quick Add'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.calories,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    onPressed: _showQuickAddMealDialog,
                  ),
                  const SizedBox(width: 8),
                  // Regular add button
                  TextButton.icon(
                    onPressed: () {
                      _tabController.animateTo(1); // Switch to Add Meal tab
                    },
                    icon: FaIcon(
                      AppAssets.iconAdd,
                      size: AppDimensions.iconSmall,
                    ),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s16),
          _buildMealsList(),
        ],
      ),
    );
  }

  Widget _buildCalorieCard() {
    final progress = _caloricInfo['consumed'] / _caloricInfo['goal'];
    final remaining = _caloricInfo['goal'] - _caloricInfo['consumed'];
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.calories.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Calorie stats section
          Padding(
            padding: const EdgeInsets.all(AppDimensions.s20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calories Today',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppDimensions.s8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_caloricInfo['consumed']}',
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.calories,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                ' / ${_caloricInfo['goal']} kcal',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.s8),
                      decoration: BoxDecoration(
                        color: AppColors.calories.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      child: FaIcon(
                        AppAssets.iconCalories,
                        size: AppDimensions.iconLarge,
                        color: AppColors.calories,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.s24),
                
                // Calorie circle progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    AnimatedCircularProgress(
                      value: progress,
                      color: AppColors.calories,
                      size: 150,
                      strokeWidth: 12,
                      centerText: '${(progress * 100).toInt()}%',
                    ),
                    
                    // Macro distribution
                    _buildMacroDistribution(),
                  ],
                ),
                
                const SizedBox(height: AppDimensions.s16),
                
                Text(
                  '$remaining kcal remaining',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          // Meal breakdown bar
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.s16,
              horizontal: AppDimensions.s20,
            ),
            decoration: BoxDecoration(
              color: AppColors.calories.withOpacity(0.08),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppDimensions.radiusLarge),
                bottomRight: Radius.circular(AppDimensions.radiusLarge),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMealStat('Breakfast', _caloricInfo['breakfast']),
                _buildVerticalDivider(),
                _buildMealStat('Lunch', _caloricInfo['lunch']),
                _buildVerticalDivider(),
                _buildMealStat('Dinner', _caloricInfo['dinner']),
                _buildVerticalDivider(),
                _buildMealStat('Snacks', _caloricInfo['snacks']),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroDistribution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Macros',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppDimensions.s12),
        _buildMacroBar('Carbs', _macroPercentages['carbs']!, Colors.amber),
        const SizedBox(height: AppDimensions.s8),
        _buildMacroBar('Protein', _macroPercentages['protein']!, Colors.green),
        const SizedBox(height: AppDimensions.s8),
        _buildMacroBar('Fat', _macroPercentages['fat']!, Colors.red.shade300),
      ],
    );
  }

  Widget _buildMacroBar(String name, double percentage, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            name,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        SizedBox(
          width: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 8,
                width: 100 * percentage,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${(percentage * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMealStat(String label, int calories) {
    return Column(
      children: [
        Text(
          '$calories',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _buildMealsList() {
    if (_todayMeals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              AppAssets.lottieCalories,
              width: 150,
              height: 150,
              repeat: true,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.fastfood,
                  size: 60,
                  color: AppColors.calories.withOpacity(0.3),
                );
              },
            ),
            const SizedBox(height: AppDimensions.s16),
            Text(
              'No meals logged today',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppDimensions.s8),
            TextButton.icon(
              onPressed: () {
                _tabController.animateTo(1); // Switch to Add Meal tab
              },
              icon: FaIcon(
                AppAssets.iconAdd,
                size: AppDimensions.iconSmall,
              ),
              label: const Text('Add Your First Meal'),
            ),
          ],
        ),
      );
    }
    
    // Sort meals by time
    final sortedMeals = List<Map<String, dynamic>>.from(_todayMeals)
      ..sort((a, b) {
        final flutterTimeA = a['time'];
        final flutterTimeB = b['time'];
        final minutesA = flutterTimeA.hour * 60 + flutterTimeA.minute;
        final minutesB = flutterTimeB.hour * 60 + flutterTimeB.minute;
        return minutesA.compareTo(minutesB);
      });
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedMeals.length,
      itemBuilder: (context, index) {
        final meal = sortedMeals[index];
        return _buildMealItem(meal, index);
      },
    );
  }

  Widget _buildMealItem(Map<String, dynamic> meal, int index) {
    final IconData typeIcon = _getMealTypeIcon(meal['type']);
    
    return Dismissible(
      key: Key('meal_${meal['id']}'),
      background: Container(
        color: AppColors.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s16),
        child: const FaIcon(
          FontAwesomeIcons.trash,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        // Show a confirmation dialog
        return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Meal'),
              content: Text('Are you sure you want to delete "${meal['name']}"?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete', style: TextStyle(color: AppColors.error)),
                ),
              ],
            );
          },
        ) ?? false; // Default to false if dialog is dismissed
      },
      onDismissed: (direction) {
        // Delete the meal from database first, then update UI
        _mealService.deleteMealEntry(meal['id']);
        
        setState(() {
          _todayMeals.removeWhere((m) => m['id'] == meal['id']);
          _loadMeals(); // Reload meal data to update stats
          _appState.notifyDataChanged(); // Notify that data has changed
        });
        
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${meal['name']} deleted'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: Colors.white,
              onPressed: () {
                // Implement undo logic if needed
              },
            ),
          ),
        );
      },
      child: InkWell(
        onTap: () {
          // Get full meal entry to show in dialog
          final mealEntries = _mealService.getMealEntriesForDay(_selectedDate);
          final mealEntry = mealEntries.firstWhere(
            (entry) => entry.id == meal['id'],
            orElse: () => _createMealEntry(meal),
          );
          
          // Show nutrition dialog
          showDialog(
            context: context,
            builder: (context) => MealNutritionDialog(meal: mealEntry),
          );
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Card(
          margin: const EdgeInsets.only(bottom: AppDimensions.s16),
          color: Theme.of(context).cardTheme.color ?? Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: _buildMealCardContent(meal, typeIcon),
        ),
      ),
    );
  }

  // Build meal card content with image support
  Widget _buildMealCardContent(Map<String, dynamic> meal, IconData typeIcon) {
    final bool hasImage = meal['hasImage'] == true;
    final String? imageUrl = meal['imageUrl'] ?? 
        (meal['imageUrls'] != null && (meal['imageUrls'] as List).isNotEmpty 
            ? (meal['imageUrls'] as List).first 
            : null);

    return Column(
      children: [
        // Meal image if available
        if (hasImage && imageUrl != null) ...[
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.radiusMedium),
              topRight: Radius.circular(AppDimensions.radiusMedium),
            ),
            child: Image.network(
              imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading meal image: $error');
                return Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.grey.shade600,
                          size: 40,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Image not available',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / 
                            loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        
        // Meal info section
        Padding(
          padding: const EdgeInsets.all(AppDimensions.s16),
          child: Row(
            children: [
              // Show icon only if no image
              if (!hasImage) ...[
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.calories.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: Center(
                    child: FaIcon(
                      typeIcon,
                      size: AppDimensions.iconMedium,
                      color: AppColors.calories,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.s16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal['name'],
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        FaIcon(
                          typeIcon,
                          size: 14,
                          color: AppColors.calories,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${meal['type'][0].toUpperCase()}${meal['type'].substring(1)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.calories,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${_formatTimeOfDay(meal['time'])}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${meal['calories']}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.calories,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    'kcal',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.calories,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomMealsTab() {
    if (_customMeals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              AppAssets.iconMeals,
              size: 60,
              color: AppColors.calories.withOpacity(0.3),
            ),
            const SizedBox(height: AppDimensions.s16),
            Text(
              'No custom meals yet',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppDimensions.s8),
            ElevatedButton(
              onPressed: () {
                _tabController.animateTo(1); // Switch to Add Meal tab
              },
              child: const Text('Create Your First Meal'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppDimensions.s16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search for a meal',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppDimensions.s12,
                horizontal: AppDimensions.s16,
              ),
            ),
            onChanged: (value) {
              // Filter meals (in a real app)
              setState(() {});
            },
          ),
        ),
        
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.s16),
            children: [
              // Display meals by type
              if (_customMealsByType['breakfast']!.isNotEmpty) 
                _buildMealTypeSection('Breakfast', 'breakfast'),
              
              if (_customMealsByType['lunch']!.isNotEmpty) 
                _buildMealTypeSection('Lunch', 'lunch'),
              
              if (_customMealsByType['dinner']!.isNotEmpty) 
                _buildMealTypeSection('Dinner', 'dinner'),
              
              if (_customMealsByType['snack']!.isNotEmpty) 
                _buildMealTypeSection('Snacks', 'snack'),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildMealTypeSection(String title, String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.s12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        
        // Grid of meals for this type
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppDimensions.s16,
            mainAxisSpacing: AppDimensions.s16,
            childAspectRatio: 0.75, // Adjusted to give more vertical space
          ),
          itemCount: _customMealsByType[type]!.length,
          itemBuilder: (context, index) {
            final meal = _customMealsByType[type]![index];
            return _buildCustomMealCard(meal);
          },
        ),
        
        const SizedBox(height: AppDimensions.s24),
      ],
    );
  }

  Widget _buildCustomMealCard(CustomMeal meal) {
    return Hero(
      tag: 'custom_meal_${meal.id}',
      child: Card(
        elevation: 3,
        shadowColor: AppColors.calories.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: InkWell(
          onTap: () {
            _showCustomMealOptions(meal);
          },
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.s12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Set mainAxisSize to min
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.calories.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: FaIcon(
                      _getMealTypeIcon(meal.mealType),
                      size: AppDimensions.iconMedium,
                      color: AppColors.calories,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.s8), // Reduced spacing
                Text(
                  meal.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppDimensions.s4),
                Text(
                  '${meal.calories} kcal',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.calories,
                      ),
                ),
                if (meal.portion != null)
                  Text(
                    meal.portion!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                const SizedBox(height: 4), // Use a fixed small height instead of Spacer
                Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  spacing: 2,
                  children: [
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.plus, size: 16),
                      color: AppColors.calories,
                      tooltip: 'Add to Today',
                      padding: const EdgeInsets.all(6), // Reduced padding
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        _showCustomMealOptions(meal);
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.pen, size: 16),
                      color: Colors.blue,
                      tooltip: 'Edit',
                      padding: const EdgeInsets.all(6), // Reduced padding
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        // Edit meal (to be implemented)
                      },
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.trash, size: 16),
                      color: Colors.red,
                      tooltip: 'Delete',
                      padding: const EdgeInsets.all(6), // Reduced padding
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        _deleteCustomMeal(meal);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showCustomMealOptions(CustomMeal meal) {
    // Controllers for the dialog
    final portionController = TextEditingController(text: meal.portion);
    final caloriesController = TextEditingController(text: meal.calories.toString());
    String selectedType = meal.mealType;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add ${meal.name} to Today',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Customize before adding',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Meal type selection
                  Text('Meal Type', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  
                  // Horizontal list of meal types
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildTypeOption('breakfast', 'Breakfast', FontAwesomeIcons.bacon, 
                          selectedType, (type) => setState(() => selectedType = type)),
                        _buildTypeOption('lunch', 'Lunch', FontAwesomeIcons.bowlRice, 
                          selectedType, (type) => setState(() => selectedType = type)),
                        _buildTypeOption('dinner', 'Dinner', FontAwesomeIcons.drumstickBite, 
                          selectedType, (type) => setState(() => selectedType = type)),
                        _buildTypeOption('snack', 'Snack', FontAwesomeIcons.appleWhole, 
                          selectedType, (type) => setState(() => selectedType = type)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Portion input
                  TextField(
                    controller: portionController,
                    decoration: InputDecoration(
                      labelText: 'Portion',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      prefixIcon: const Icon(Icons.restaurant),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Calories input
                  TextField(
                    controller: caloriesController,
                    decoration: InputDecoration(
                      labelText: 'Calories',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                      prefixIcon: const Icon(Icons.local_fire_department),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Add button
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            
                            // Add the customized meal to today
                            _addCustomizedMealToToday(
                              meal,
                              selectedType,
                              portionController.text,
                              int.tryParse(caloriesController.text) ?? meal.calories,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.calories,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Add to Today'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildTypeOption(String type, String label, IconData icon, 
      String selectedType, Function(String) onSelected) {
    
    final isSelected = type == selectedType;
    
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => onSelected(type),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.calories : AppColors.calories.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: Row(
            children: [
              FaIcon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.calories,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.calories,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _addCustomizedMealToToday(
    CustomMeal meal,
    String mealType,
    String? portion,
    int calories,
  ) {
    // Use the selected date instead of always using "now"
    final entryDate = _selectedDate;
    final currentTime = flutter.TimeOfDay.now();
    
    // Create a proper models.TimeOfDay from Flutter.TimeOfDay
    final timeOfDay = models.TimeOfDay(
      hour: currentTime.hour,
      minute: currentTime.minute
    );
    
    // Create MealEntry from CustomMeal with customizations
    final entry = meal.toMealEntry(
      date: entryDate,
      timeOfDay: timeOfDay,
      customCalories: calories,
      customPortion: portion,
      customMealType: mealType,
    );
    
    // Save to SharedPreferences
    _mealService.addMealEntry(entry);
    
    // Refresh data
    _loadMeals();
    
    // Explicitly notify the app state that data has changed
    // This will trigger refresh of the dashboard
    _appState.notifyDataChanged();
    
    // Switch to Today tab
    _tabController.animateTo(0);
    
    // Show confirmation with animation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${meal.name} added to ${_selectedDate.year == DateTime.now().year && 
           _selectedDate.month == DateTime.now().month && 
           _selectedDate.day == DateTime.now().day ? 
           "today's" : "selected date's"} meals'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => _tabController.animateTo(0),
        ),
      ),
    );
  }
  
  void _deleteCustomMeal(CustomMeal meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Meal'),
        content: Text('Are you sure you want to delete "${meal.name}" from your custom meals?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _mealService.deleteCustomMeal(meal.id);
              
              // Reload data after deletion
              _loadMeals();
              _appState.notifyDataChanged(); // Notify that data has changed
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${meal.name} deleted from My Meals'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'UNDO',
                    textColor: Colors.white,
                    onPressed: () {
                      // Implement undo logic if needed
                    },
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getMealTypeIcon(String type) {
    switch (type) {
      case 'breakfast':
        return FontAwesomeIcons.bacon;
      case 'lunch':
        return FontAwesomeIcons.bowlRice;
      case 'dinner':
        return FontAwesomeIcons.drumstickBite;
      case 'snack':
        return FontAwesomeIcons.appleWhole;
      default:
        return AppAssets.iconMeals;
    }
  }

  String _formatTimeOfDay(flutter.TimeOfDay time) {
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  // Add a method to directly update the meal form with analysis results
  void _fillMealFormFromAnalysis(FoodAnalysisResult result) {
    // Error Recovery 1: Handle null or invalid result
    if (result.foodName.isEmpty || result.calories <= 0) {
      debugPrint('ERROR: Invalid analysis result - missing name or calories');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid analysis result - please try again'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    debugPrint('FILLING MEAL FORM FROM AI ANALYSIS:');
    debugPrint('- Food Name: ${result.foodName}');
    debugPrint('- Calories: ${result.calories}');
    debugPrint('- Protein: ${result.protein}g');
    debugPrint('- Carbs: ${result.carbs}g');
    debugPrint('- Fat: ${result.fat}g');
    debugPrint('- Image URL: ${result.imageUrl}');
    debugPrint('- Is Low Fat: ${result.isLowFat}');
    debugPrint('- Diet Type: ${result.dietType}');
    
    // Switch to the Add Meal tab
    setState(() {
      _tabController.animateTo(1);
    });
    
    // Calculate percentages from result for UI feedback
    int proteinPercent = (result.proteinPercentage * 100).round();
    int carbsPercent = (result.carbsPercentage * 100).round();
    int fatPercent = (result.fatPercentage * 100).round();
    
    debugPrint('AI Analysis Percentages: Protein=$proteinPercent%, Carbs=$carbsPercent%, Fat=$fatPercent%');
    
    // We need to wait for the widget to be built before setting values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // Get reference to the meal form state
        final mealFormState = mealFormKey.currentState;
        if (mealFormState != null && mealFormState.mounted) {
          // Cast to get access to the updateFromEnhancedAIResult method
          final formScreenState = mealFormState as dynamic;
          if (formScreenState.updateFromEnhancedAIResult != null) {
            formScreenState.updateFromEnhancedAIResult(result);
            debugPrint('SUCCESS: Updated meal form with enhanced AI result');
          } else {
            debugPrint('WARNING: Enhanced update method not found, trying basic update');
            // Fall back to basic update
            if (formScreenState.updateFromAIResult != null) {
              formScreenState.updateFromAIResult(
                result.foodName,
                result.calories,
                result.protein,
                result.fat,
                result.carbs
              );
            }
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('AI Analysis: ${result.foodName} - P:${proteinPercent}% C:${carbsPercent}% F:${fatPercent}%'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          throw Exception('Meal form not available');
        }
      } catch (e) {
        debugPrint('ERROR updating meal form: $e');
        
        // Show the analysis result in a dialog so user can manually enter
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('AI Analysis Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Food: ${result.foodName}'),
                Text('Calories: ${result.calories}'),
                Text('Protein: ${result.protein}g (${proteinPercent}%)'),
                Text('Carbs: ${result.carbs}g (${carbsPercent}%)'),
                Text('Fat: ${result.fat}g (${fatPercent}%)'),
                if (result.imageUrl != null) Text('Image: ✓ Uploaded'),
                if (result.isLowFat) Text('✓ Low Fat'),
                Text('Diet: ${result.dietType}'),
                const SizedBox(height: 8),
                const Text('Please enter this information manually in the form.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
  }

  // New helper method for retrying meal addition
  Future<void> _createAndSaveMeal(Map<String, dynamic> meal) async {
    try {
      debugPrint('RETRYING MEAL ADDITION: ${meal['name']}');
      
      // Create a MealEntry
      final entry = MealEntry(
        date: _selectedDate,
        name: meal['name'],
        calories: meal['calories'],
        mealType: meal['type'],
        timeOfDay: models.TimeOfDay(
          hour: (meal['time'] as flutter.TimeOfDay).hour,
          minute: (meal['time'] as flutter.TimeOfDay).minute
        ),
        portion: meal['portion'],
      );
      
      // Save directly to avoid any callback issues
      await _mealService.addMealEntry(entry);
      
      // Reload data
      await _loadMeals();
      
      // Explicitly notify the app state that data has changed
      // This will trigger refresh of the dashboard
      _appState.notifyDataChanged();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${meal['name']} has been added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('ERROR IN RETRY: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add meal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show dialog to quickly add a meal
  void _showQuickAddMealDialog() {
    final mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
    String selectedType = 'lunch';
    int calories = 300;
    String name = 'Quick Meal';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Quick Add Meal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Meal name
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Meal Name',
                  hintText: 'Quick Meal',
                ),
                onChanged: (value) => name = value.isNotEmpty ? value : 'Quick Meal',
              ),
              const SizedBox(height: 16),
              
              // Calorie slider
              Text('Calories: $calories', style: Theme.of(context).textTheme.titleMedium),
              Slider(
                value: calories.toDouble(),
                min: 50,
                max: 1000,
                divisions: 19,
                label: calories.toString(),
                activeColor: AppColors.calories,
                onChanged: (value) {
                  setState(() {
                    calories = value.round();
                  });
                },
              ),
              
              // Meal type selection
              const SizedBox(height: 8),
              const Text('Meal Type'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: mealTypes.map((type) => 
                  ChoiceChip(
                    label: Text(_getMealTypeLabel(type)),
                    selected: selectedType == type,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedType = type;
                        });
                      }
                    },
                  )
                ).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _addQuickMeal(name, calories, selectedType);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.calories,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Meal'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper to get display label for meal types
  String _getMealTypeLabel(String type) {
    switch (type) {
      case 'breakfast': return 'Breakfast';
      case 'lunch': return 'Lunch';
      case 'dinner': return 'Dinner';
      case 'snack': return 'Snack';
      default: return 'Meal';
    }
  }
  
  // Add a quick meal from the dialog
  Future<void> _addQuickMeal(String name, int calories, String mealType) async {
    try {
      final currentTime = flutter.TimeOfDay.now();
      
      // Create meal entry directly
      final entry = MealEntry(
        date: _selectedDate, 
        name: name,
        calories: calories,
        mealType: mealType,
        timeOfDay: models.TimeOfDay(
          hour: currentTime.hour,
          minute: currentTime.minute
        ),
      );
      
      // Save with extra error handling
      bool success = await _mealService.addMealEntry(entry);
      
      if (!success) {
        debugPrint('Failed to add meal via regular method, trying again...');
        
        // Try with a fresh service instance
        final freshService = MealService();
        await freshService.init();
        success = await freshService.addMealEntry(entry);
      }
      
      // Reload meals with a slight delay to allow for database write
      await Future.delayed(const Duration(milliseconds: 300));
      await _loadMeals();
      
      // Explicitly notify the app state that data has changed
      // This will trigger refresh of the dashboard
      debugPrint('NOTIFY APP STATE: Meal added - ${entry.name}, ${entry.calories} calories');
      _appState.notifyDataChanged();
      
      // Show success or failure message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '$name added successfully' : 'Error adding meal, please try again'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      debugPrint('Error adding quick meal: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 