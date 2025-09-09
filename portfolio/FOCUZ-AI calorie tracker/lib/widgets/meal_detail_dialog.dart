import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/meal_data.dart';

class MealDetailDialog extends StatelessWidget {
  final MealEntry meal;

  const MealDetailDialog({
    super.key,
    required this.meal,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with meal type icon and name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getMealTypeColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FaIcon(
                      _getMealTypeIcon(),
                      color: _getMealTypeColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getMealTypeDisplayName(),
                          style: TextStyle(
                            fontSize: 14,
                            color: _getMealTypeColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Images section
              if (meal.imageUrls.isNotEmpty) ...[
                Text(
                  'Images',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildImageCarousel(context),
                const SizedBox(height: 24),
              ],
              
              // Meal info section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.local_fire_department,
                      label: 'Calories',
                      value: '${meal.calories}',
                      color: Colors.orange,
                    ),
                    if (meal.portion != null) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.straighten,
                        label: 'Portion',
                        value: meal.portion!,
                        color: Colors.blue,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.access_time,
                      label: 'Time',
                      value: meal.timeOfDay.toFlutterTimeOfDay().format(context),
                      color: Colors.green,
                    ),
                    if (meal.estimatedWeight > 0) ...[
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.scale,
                        label: 'Weight',
                        value: '~${meal.estimatedWeight.toInt()}g',
                        color: Colors.purple,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Nutrition section
              if (meal.macros != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Nutrition',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildNutritionSection(),
              ],
              
              // Diet info section
              if (meal.isLowFat || meal.dietType != 'Standard') ...[
                const SizedBox(height: 24),
                Text(
                  'Diet Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (meal.isLowFat)
                      Chip(
                        label: const Text('Low Fat'),
                        backgroundColor: Colors.green.shade100,
                        side: BorderSide(color: Colors.green.shade300),
                      ),
                    if (meal.dietType != 'Standard')
                      Chip(
                        label: Text(meal.dietType),
                        backgroundColor: Colors.blue.shade100,
                        side: BorderSide(color: Colors.blue.shade300),
                      ),
                  ],
                ),
              ],
              
              // Notes section
              if (meal.additionalInfo != null && meal.additionalInfo!['notes'] != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    meal.additionalInfo!['notes'].toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(BuildContext context) {
    if (meal.imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: () => _showFullScreenImage(context, meal.imageUrls.first),
          child: Image.network(
            meal.imageUrls.first,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey.shade300,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Failed to load image'),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: meal.imageUrls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () => _showFullScreenImage(context, meal.imageUrls[index]),
                child: Stack(
                  children: [
                    Image.network(
                      meal.imageUrls[index],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey.shade300,
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Failed to load image'),
                            ],
                          ),
                        );
                      },
                    ),
                    if (meal.imageUrls.length > 1)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${index + 1}/${meal.imageUrls.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionSection() {
    final macros = meal.macros!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Macro values in grams
          Row(
            children: [
              Expanded(child: _buildMacroColumn('Protein', macros.proteinGrams, 'g', Colors.red.shade400)),
              Expanded(child: _buildMacroColumn('Carbs', macros.carbsGrams, 'g', Colors.green.shade400)),
              Expanded(child: _buildMacroColumn('Fat', macros.fatGrams, 'g', Colors.orange.shade400)),
            ],
          ),
          
          if (macros.fiberGrams != null && macros.fiberGrams! > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.eco, color: Colors.brown, size: 20),
                const SizedBox(width: 8),
                const Text('Fiber', style: TextStyle(fontWeight: FontWeight.w500)),
                const Spacer(),
                Text(
                  '${macros.fiberGrams!.toStringAsFixed(1)}g',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Macro percentage distribution
          _buildMacroPercentageBar(macros),
        ],
      ),
    );
  }

  Widget _buildMacroColumn(String label, double value, String unit, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            label == 'Protein' ? Icons.fitness_center :
            label == 'Carbs' ? Icons.grain : Icons.water_drop,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${value.toStringAsFixed(1)}$unit',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroPercentageBar(Macros macros) {
    final proteinCals = macros.proteinGrams * 4;
    final carbsCals = macros.carbsGrams * 4;
    final fatCals = macros.fatGrams * 9;
    final totalCals = proteinCals + carbsCals + fatCals;
    
    if (totalCals <= 0) return const SizedBox.shrink();
    
    final proteinPercent = proteinCals / totalCals;
    final carbsPercent = carbsCals / totalCals;
    final fatPercent = fatCals / totalCals;
    
    return Column(
      children: [
        const Text(
          'Calorie Distribution',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              if (proteinPercent > 0)
                Expanded(
                  flex: (proteinPercent * 100).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        bottomLeft: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              if (carbsPercent > 0)
                Expanded(
                  flex: (carbsPercent * 100).round(),
                  child: Container(
                    color: Colors.green.shade400,
                  ),
                ),
              if (fatPercent > 0)
                Expanded(
                  flex: (fatPercent * 100).round(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.orange.shade400,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('${(proteinPercent * 100).round()}%', style: const TextStyle(fontSize: 10)),
            Text('${(carbsPercent * 100).round()}%', style: const TextStyle(fontSize: 10)),
            Text('${(fatPercent * 100).round()}%', style: const TextStyle(fontSize: 10)),
          ],
        ),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.white, size: 64),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMealTypeIcon() {
    switch (meal.mealType.toLowerCase()) {
      case 'breakfast':
        return FontAwesomeIcons.bacon;
      case 'lunch':
        return FontAwesomeIcons.bowlRice;
      case 'dinner':
        return FontAwesomeIcons.drumstickBite;
      case 'snack':
        return FontAwesomeIcons.appleWhole;
      default:
        return FontAwesomeIcons.utensils;
    }
  }

  Color _getMealTypeColor() {
    switch (meal.mealType.toLowerCase()) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.red;
      case 'snack':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getMealTypeDisplayName() {
    return meal.mealType.substring(0, 1).toUpperCase() + meal.mealType.substring(1);
  }
}

// Helper function to show meal detail dialog
void showMealDetailDialog(BuildContext context, MealEntry meal) {
  showDialog(
    context: context,
    builder: (context) => MealDetailDialog(meal: meal),
  );
} 