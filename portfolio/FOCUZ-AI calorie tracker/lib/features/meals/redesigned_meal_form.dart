import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/assets.dart';
import '../../core/constants.dart';
import '../../models/meal_data.dart' as models;
import '../../services/meal_service.dart';
import '../../services/cloudinary_service.dart';
import '../../services/daily_metrics_service.dart';

class RedesignedMealFormScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onMealAdded;
  final Map<String, dynamic>? existingMeal;
  final bool isEditingCustomMeal;
  final DateTime? selectedDate;
  final String? initialName;
  final int? initialCalories;
  final double? initialProtein;
  final double? initialFat;
  final double? initialCarbs;
  final double? initialFiber;
  final List<String>? initialImageUrls;
  final double? initialEstimatedWeight;
  final bool? initialIsLowFat;
  final String? initialDietType;

  const RedesignedMealFormScreen({
    super.key,
    this.onMealAdded,
    this.existingMeal,
    this.isEditingCustomMeal = false,
    this.selectedDate,
    this.initialName,
    this.initialCalories,
    this.initialProtein,
    this.initialFat,
    this.initialCarbs,
    this.initialFiber,
    this.initialImageUrls,
    this.initialEstimatedWeight,
    this.initialIsLowFat,
    this.initialDietType,
  });

  @override
  State<RedesignedMealFormScreen> createState() => _RedesignedMealFormScreenState();
}

class _RedesignedMealFormScreenState extends State<RedesignedMealFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mealService = MealService();
  final _dailyMetricsService = DailyMetricsService();
  final _imagePicker = ImagePicker();
  final _scrollController = ScrollController();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _portionController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();
  final _notesController = TextEditingController();
  
  // Form state
  String _selectedMealType = 'breakfast';
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLowFat = false;
  String _dietType = 'Standard';
  bool _showNutrientDetails = false;
  bool _isSaving = false;
  
  // Image handling
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  bool _isUploadingImages = false;
  
  // Meal types with icons and colors
  final List<Map<String, dynamic>> _mealTypes = [
    {
      'type': 'breakfast',
      'name': 'Breakfast',
      'icon': FontAwesomeIcons.bacon,
      'color': Colors.orange,
    },
    {
      'type': 'lunch',
      'name': 'Lunch',
      'icon': FontAwesomeIcons.bowlRice,
      'color': Colors.green,
    },
    {
      'type': 'dinner',
      'name': 'Dinner',
      'icon': FontAwesomeIcons.drumstickBite,
      'color': Colors.red,
    },
    {
      'type': 'snack',
      'name': 'Snack',
      'icon': FontAwesomeIcons.appleWhole,
      'color': Colors.purple,
    },
  ];
  
  final List<String> _dietTypes = ['Standard', 'Keto', 'Carnivore', 'Vegetarian', 'Vegan'];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Initialize with passed data
    if (widget.initialName != null) _nameController.text = widget.initialName!;
    if (widget.initialCalories != null) _caloriesController.text = widget.initialCalories.toString();
    if (widget.initialProtein != null) _proteinController.text = widget.initialProtein!.toStringAsFixed(1);
    if (widget.initialFat != null) _fatController.text = widget.initialFat!.toStringAsFixed(1);
    if (widget.initialCarbs != null) _carbsController.text = widget.initialCarbs!.toStringAsFixed(1);
    if (widget.initialFiber != null) _fiberController.text = widget.initialFiber!.toStringAsFixed(1);
    if (widget.initialEstimatedWeight != null && widget.initialEstimatedWeight! > 0) {
      _portionController.text = '~${widget.initialEstimatedWeight!.toInt()}g';
    }
    if (widget.initialIsLowFat != null) _isLowFat = widget.initialIsLowFat!;
    if (widget.initialDietType != null) _dietType = widget.initialDietType!;
    if (widget.initialImageUrls != null) _existingImageUrls = List.from(widget.initialImageUrls!);
    
    // Show nutrient details if any macro data is provided
    if (widget.initialProtein != null || widget.initialFat != null || 
        widget.initialCarbs != null || widget.initialFiber != null) {
      _showNutrientDetails = true;
    }
    
    // Set appropriate meal type based on current time
    _selectedMealType = _determineMealType();
    _selectedTime = TimeOfDay.now();
  }

  String _determineMealType() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 10) return 'breakfast';
    if (hour >= 10 && hour < 14) return 'lunch';
    if (hour >= 14 && hour < 18) return 'snack';
    if (hour >= 18 && hour < 22) return 'dinner';
    return 'snack';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.isEditingCustomMeal ? 'Edit Meal' : 'Add Meal'),
        actions: [
          if (_showNutrientDetails)
            TextButton(
              onPressed: () => setState(() => _showNutrientDetails = false),
              child: const Text('Simple'),
            )
          else
            TextButton(
              onPressed: () => setState(() => _showNutrientDetails = true),
              child: const Text('Detailed'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMealBasicsSection(),
                    const SizedBox(height: 16),
                    _buildMealTypeSelector(),
                    const SizedBox(height: 16),
                    _buildTimeSelector(),
                    const SizedBox(height: 16),
                    if (_showNutrientDetails) ...[
                      _buildNutrientDetailsSection(),
                      const SizedBox(height: 16),
                      _buildDietPreferencesSection(),
                      const SizedBox(height: 16),
                    ],
                    _buildImageSection(),
                    const SizedBox(height: 16),
                    _buildNotesSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMealBasicsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meal Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Meal Name',
                hintText: 'Enter meal name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a meal name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _caloriesController,
                    decoration: const InputDecoration(
                      labelText: 'Calories',
                      hintText: '0',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_fire_department),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      final calories = int.tryParse(value);
                      if (calories == null || calories <= 0) {
                        return 'Enter valid calories';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _portionController,
                    decoration: const InputDecoration(
                      labelText: 'Portion',
                      hintText: '1 serving',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.straighten),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meal Type',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: _mealTypes.map((mealType) {
                final isSelected = _selectedMealType == mealType['type'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMealType = mealType['type']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? mealType['color'] : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? mealType['color'] : Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            FaIcon(
                              mealType['icon'],
                              color: isSelected ? Colors.white : mealType['color'],
                              size: 20,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mealType['name'],
                              style: TextStyle(
                                color: isSelected ? Colors.white : null,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.access_time),
            const SizedBox(width: 16),
            Text(
              'Time: ${_selectedTime.format(context)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton(
              onPressed: _selectTime,
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutritional Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _proteinController,
                    decoration: const InputDecoration(
                      labelText: 'Protein (g)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.fitness_center),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _carbsController,
                    decoration: const InputDecoration(
                      labelText: 'Carbs (g)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.grain),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fatController,
                    decoration: const InputDecoration(
                      labelText: 'Fat (g)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.water_drop),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _fiberController,
                    decoration: const InputDecoration(
                      labelText: 'Fiber (g)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.eco),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            if (_hasValidMacros()) ...[
              const SizedBox(height: 16),
              _buildMacroChart(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDietPreferencesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diet Preferences',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _dietType,
              decoration: const InputDecoration(
                labelText: 'Diet Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant_menu),
              ),
              items: _dietTypes.map((diet) {
                return DropdownMenuItem(
                  value: diet,
                  child: Text(diet),
                );
              }).toList(),
              onChanged: (value) => setState(() => _dietType = value!),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Low Fat Food'),
              subtitle: const Text('Mark if this food is under 10% fat'),
              value: _isLowFat,
              onChanged: (value) => setState(() => _isLowFat = value),
              secondary: const Icon(Icons.spa),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Images (${_selectedImages.length + _existingImageUrls.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Image grid
            if (_selectedImages.isNotEmpty || _existingImageUrls.isNotEmpty) ...[
              _buildImageGrid(),
              const SizedBox(height: 16),
            ],
            
            // Add image buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingImages ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingImages ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            
            if (_isUploadingImages)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    final totalImages = _existingImageUrls.length + _selectedImages.length;
    
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: totalImages,
        itemBuilder: (context, index) {
          final isExistingImage = index < _existingImageUrls.length;
          
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 8),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: isExistingImage
                      ? Image.network(
                          _existingImageUrls[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 120,
                              height: 120,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.error),
                            );
                          },
                        )
                      : Image.file(
                          _selectedImages[index - _existingImageUrls.length],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Add any additional notes about this meal...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroChart() {
    final protein = double.tryParse(_proteinController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fat = double.tryParse(_fatController.text) ?? 0;
    
    final proteinCals = protein * 4;
    final carbsCals = carbs * 4;
    final fatCals = fat * 9;
    final totalCals = proteinCals + carbsCals + fatCals;
    
    if (totalCals <= 0) return const SizedBox.shrink();
    
    final proteinPercent = (proteinCals / totalCals * 100).round();
    final carbsPercent = (carbsCals / totalCals * 100).round();
    final fatPercent = (fatCals / totalCals * 100).round();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Macro Distribution',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMacroBar('Protein', proteinPercent, Colors.red.shade300),
              const SizedBox(width: 8),
              _buildMacroBar('Carbs', carbsPercent, Colors.green.shade300),
              const SizedBox(width: 8),
              _buildMacroBar('Fat', fatPercent, Colors.orange.shade300),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroBar(String label, int percent, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$percent%',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving || _isUploadingImages ? null : _saveMeal,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  widget.isEditingCustomMeal ? 'Update Meal' : 'Save Meal',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  bool _hasValidMacros() {
    final protein = double.tryParse(_proteinController.text) ?? 0;
    final carbs = double.tryParse(_carbsController.text) ?? 0;
    final fat = double.tryParse(_fatController.text) ?? 0;
    return protein > 0 || carbs > 0 || fat > 0;
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index < _existingImageUrls.length) {
        _existingImageUrls.removeAt(index);
      } else {
        _selectedImages.removeAt(index - _existingImageUrls.length);
      }
    });
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Upload new images to Cloudinary
      List<String> allImageUrls = List.from(_existingImageUrls);
      
      if (_selectedImages.isNotEmpty) {
        setState(() => _isUploadingImages = true);
        
        final cloudinaryService = CloudinaryService();
        for (final imageFile in _selectedImages) {
          try {
            final imageUrl = await cloudinaryService.uploadImage(imageFile, imageType: 'meal');
            if (imageUrl != null) {
              allImageUrls.add(imageUrl);
            }
          } catch (e) {
            debugPrint('Error uploading image: $e');
          }
        }
        
        setState(() => _isUploadingImages = false);
      }

      // Create macros object if nutrition data is provided
      models.Macros? macros;
      if (_hasValidMacros()) {
        macros = models.Macros(
          proteinGrams: double.tryParse(_proteinController.text) ?? 0,
          carbsGrams: double.tryParse(_carbsController.text) ?? 0,
          fatGrams: double.tryParse(_fatController.text) ?? 0,
          fiberGrams: double.tryParse(_fiberController.text) ?? 0,
        );
      }

      // Save meal using the meal provider
      await _mealService.init();
      
      final calories = int.parse(_caloriesController.text);
      final portion = _portionController.text.trim().isEmpty ? '1 serving' : _portionController.text.trim();
      
      // Use the existing meal provider to save the meal
      await _mealService.addMealEntry(
        models.MealEntry(
          name: _nameController.text.trim(),
          calories: calories,
          mealType: _selectedMealType,
          date: widget.selectedDate ?? DateTime.now(),
          timeOfDay: models.TimeOfDay.fromFlutterTimeOfDay(_selectedTime),
          portion: portion,
          macros: macros,
          isLowFat: _isLowFat,
          dietType: _dietType,
          imageUrl: allImageUrls.isNotEmpty ? allImageUrls.first : null,
          imageUrls: allImageUrls,
          estimatedWeight: widget.initialEstimatedWeight ?? 0.0,
          additionalInfo: _notesController.text.trim().isNotEmpty 
              ? {'notes': _notesController.text.trim()} 
              : null,
        ),
      );

      // Call the callback if provided
      if (widget.onMealAdded != null) {
        widget.onMealAdded!({
          'name': _nameController.text.trim(),
          'calories': calories,
          'type': _selectedMealType,
          'date': widget.selectedDate ?? DateTime.now(),
          'portion': portion,
          'time': _selectedTime,
          'macros': macros?.toJson(),
          'isLowFat': _isLowFat,
          'dietType': _dietType,
          'imageUrls': allImageUrls,
          'notes': _notesController.text.trim(),
        });
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_nameController.text} saved successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate back
      Navigator.of(context).pop();

    } catch (e) {
      _showErrorSnackBar('Error saving meal: $e');
    } finally {
      setState(() {
        _isSaving = false;
        _isUploadingImages = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _portionController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
} 