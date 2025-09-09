import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import '../../core/assets.dart';
import '../../core/constants.dart';
import '../../widgets/animated_progress.dart';
import '../../models/health_data.dart';
import '../../services/health_service.dart';
import '../dashboard/dashboard_screen.dart'; // Import to access AppState
import '../../services/meal_service.dart';
import '../splash/splash_screen.dart';
import '../../widgets/custom_app_bar.dart';

class WaterCanScreen extends StatefulWidget {
  final DateTime? selectedDate;
  
  const WaterCanScreen({Key? key, this.selectedDate}) : super(key: key);

  @override
  State<WaterCanScreen> createState() => _WaterCanScreenState();
}

class _WaterCanScreenState extends State<WaterCanScreen> with SingleTickerProviderStateMixin {
  final HealthService _healthService = HealthService();
  final MealService _mealService = MealService(); 
  final TextEditingController _amountController = TextEditingController();
  final AppState _appState = AppState(); // Add reference to global app state
  
  // Water data
  double _currentValue = 0.0;
  bool _isLoading = true;
  late AnimationController _controller;
  double _maxWater = 2000; // Default in ml
  late DateTime _selectedDate;
  bool _isHistoryMode = false;
  
  // History of drinks
  List<WaterEntry> _drinkHistory = [];
  
  // Drink types
  final List<Map<String, dynamic>> _drinkTypes = [
    {'name': 'Water', 'icon': AppAssets.iconWater, 'color': AppColors.water},
    {'name': 'Coffee', 'icon': FontAwesomeIcons.mugHot, 'color': Colors.brown},
    {'name': 'Tea', 'icon': FontAwesomeIcons.mugSaucer, 'color': Colors.orange},
    {'name': 'Juice', 'icon': FontAwesomeIcons.wineGlass, 'color': Colors.purple},
    {'name': 'Soda', 'icon': FontAwesomeIcons.bottleWater, 'color': Colors.red},
  ];
  
  String _selectedDrinkType = 'Water';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    // Initialize the selectedDate from widget or use today
    _selectedDate = widget.selectedDate ?? DateTime.now();
    
    // Check if we're in history mode
    final now = DateTime.now();
    _isHistoryMode = _selectedDate.year != now.year || 
                     _selectedDate.month != now.month || 
                     _selectedDate.day != now.day;
    
    _initialize();
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _controller.dispose();
    super.dispose();
  }
  
  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _healthService.init();
      await _mealService.init();
      
      // Get water target from nutrition profile
      final nutritionProfile = _mealService.getNutritionProfile();
      if (nutritionProfile != null) {
        // Use a default water target or try to get from profile
        // NutritionProfile doesn't have dailyWaterTargetMl property
        _maxWater = 2500; // Default 2.5L in ml
      }
      
      // Load water intake for the selected date
      _currentValue = _healthService.getTotalWaterForDay(_selectedDate);
      
      // Get drink history
      _drinkHistory = _healthService.getWaterEntriesForDay(_selectedDate);
      
      // Animate the water filling
      _updateWaterAnimation();
    } catch (e) {
      print('Error loading water data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _updateWaterAnimation() {
    _controller.forward(from: 0.0);
  }
  
  Future<void> _addWater(double amount, String type) async {
    final now = DateTime.now();
    // Create a date that uses selected date but with current time
    final entryDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      now.hour,
      now.minute,
      now.second
    );
    
    final entry = WaterEntry(
      date: entryDate,
      amount: amount * 1000, // Convert L to ml for storage
      type: type,
    );
    
    await _healthService.addWaterEntry(entry);
    _loadWaterData();
    _appState.notifyDataChanged(); // Notify that data has changed
  }

  // Implement the missing method to reload water data
  void _loadWaterData() {
    // Re-initialize to reload data
    _initialize();
    
    // Update the UI with the latest data
    setState(() {
      _drinkHistory = _healthService.getWaterEntriesForDay(_selectedDate);
      _currentValue = _healthService.getTotalWaterForDay(_selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isHistoryMode 
            ? 'Water (${DateFormat('MMM d').format(_selectedDate)})' 
            : 'Water Tracker',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // History mode indicator
                  if (_isHistoryMode)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Editing water intake for ${DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate)}',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.amber,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                  // Today's progress
                  _buildWaterProgress(),
                  const SizedBox(height: AppDimensions.s32),
                  
                  // Quick add buttons
                  _buildQuickAddButtons(),
                  const SizedBox(height: AppDimensions.s32),
                  
                  // Add other drinks
                  _buildDrinkSelector(),
                  const SizedBox(height: AppDimensions.s32),
                  
                  // History
                  Text(
                    _isHistoryMode
                      ? 'Drinks on ${DateFormat('MMMM d').format(_selectedDate)}'
                      : 'Today\'s Drinks',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppDimensions.s16),
                  _buildDrinkHistory(),
                ],
              ),
            ),
    );
  }

  Widget _buildWaterProgress() {
    final progress = _currentValue / _maxWater;
    final remaining = (_maxWater - _currentValue) / 1000; // Convert to L for display
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.water.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.s20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isHistoryMode 
                        ? 'Water Intake (${DateFormat('MMM d').format(_selectedDate)})'
                        : 'Current Water Intake',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppDimensions.s4),
                    RichText(
                      text: TextSpan(
                        text: (_currentValue / 1000).toStringAsFixed(1),
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.water,
                            ),
                        children: [
                          TextSpan(
                            text: ' / ${_maxWater / 1000} L',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              FaIcon(
                AppAssets.iconWater,
                size: 40,
                color: AppColors.water,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.s24),
          
          // Animated water progress
          SizedBox(
            height: 120,
            child: AnimatedWaveProgress(
              value: progress,
              color: AppColors.water,
              height: 120,
            ),
          ),
          
          const SizedBox(height: AppDimensions.s16),
          
          Text(
            'You need to drink ${remaining.toStringAsFixed(1)} L more today',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickAddButton(0.25, 'Glass'),
        _buildQuickAddButton(0.5, 'Bottle'),
        _buildQuickAddButton(1.0, 'Large Bottle'),
        _buildQuickAddButton(0.3, 'Can'),
      ],
    );
  }

  Widget _buildQuickAddButton(double amount, String label) {
    final amountText = amount >= 1.0 ? '${amount.toInt()} L' : '${(amount * 1000).toInt()} ml';
    
    return GestureDetector(
      onTap: () {
        _addWater(amount, 'Water');
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.s16),
            decoration: BoxDecoration(
              color: AppColors.water.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              AppAssets.iconWater,
              size: AppDimensions.iconLarge,
              color: AppColors.water,
            ),
          ),
          const SizedBox(height: AppDimensions.s8),
          Text(
            amountText,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppDimensions.s4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildDrinkSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Other Drinks',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppDimensions.s16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.s16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDrinkType,
                    isExpanded: true,
                    items: _drinkTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['name'],
                        child: Row(
                          children: [
                            FaIcon(
                              type['icon'],
                              size: AppDimensions.iconSmall,
                              color: type['color'],
                            ),
                            const SizedBox(width: AppDimensions.s12),
                            Text(type['name']),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDrinkType = value!;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.s12),
            IconButton.filled(
              onPressed: () {
                _showAddDrinkDialog();
              },
              icon: FaIcon(
                AppAssets.iconAdd,
                size: AppDimensions.iconMedium,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrinkHistory() {
    if (_drinkHistory.isEmpty) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.water_drop_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: AppDimensions.s16),
              Text(
                'No drinks logged today',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _drinkHistory.length,
      itemBuilder: (context, index) {
        final drink = _drinkHistory[index];
        
        // Get icon and color for this drink type
        final drinkTypeData = _drinkTypes.firstWhere(
          (type) => type['name'] == drink.type,
          orElse: () => _drinkTypes.first,
        );
        
        return Dismissible(
          key: Key(drink.id),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: AppDimensions.s16),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            _healthService.deleteWaterEntry(drink.id);
            _loadWaterData();
          },
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Entry'),
                content: const Text('Are you sure you want to delete this drink?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: AppDimensions.s8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (drinkTypeData['color'] as Color).withOpacity(0.1),
                child: FaIcon(
                  drinkTypeData['icon'],
                  size: AppDimensions.iconMedium,
                  color: drinkTypeData['color'],
                ),
              ),
              title: Text(
                '${(drink.amount / 1000).toStringAsFixed(1)} L ${drink.type}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: Text(
                DateFormat('h:mm a').format(drink.date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _showAddDrinkDialog() {
    _amountController.text = '0.25';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $_selectedDrinkType'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (L)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final amount = double.parse(_amountController.text);
                if (amount > 0) {
                  _addWater(amount, _selectedDrinkType);
                  Navigator.of(context).pop();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid amount')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
} 