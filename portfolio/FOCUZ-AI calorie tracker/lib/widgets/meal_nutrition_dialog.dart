import 'package:flutter/material.dart';
import '../models/meal_data.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MealNutritionDialog extends StatelessWidget {
  final MealEntry meal;
  
  const MealNutritionDialog({
    super.key,
    required this.meal,
  });

  // Helper method to check if meal has any images
  bool _hasImages() {
    return meal.imageUrl != null || meal.imageUrls.isNotEmpty;
  }

  // Get the primary image URL (either single imageUrl or first from imageUrls)
  String? _getPrimaryImageUrl() {
    if (meal.imageUrl != null) {
      return meal.imageUrl;
    } else if (meal.imageUrls.isNotEmpty) {
      return meal.imageUrls.first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with meal name and close button
          _buildHeader(context),
          
          // Meal image section - check both imageUrl and imageUrls
          if (_hasImages())
            _buildImageSection(context)
          else
            _buildNoImageSection(context),
            
          // Nutrition information
          _buildNutritionInfo(context),
          
          // Footer with additional info
          _buildFooter(context),
        ],
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              meal.name,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImageSection(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        maxHeight: 200,
      ),
      child: ClipRRect(
        child: Image.network(
          _getPrimaryImageUrl()!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 150,
              color: Colors.grey.shade200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      size: 40,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Image not available',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildNoImageSection(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.image,
              size: 30,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              'No image for this meal',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNutritionInfo(BuildContext context) {
    // Debug logging
    debugPrint('NUTRITION DIALOG - Meal data:');
    debugPrint('- Name: ${meal.name}');
    debugPrint('- Calories: ${meal.calories}');
    debugPrint('- Image URL: ${meal.imageUrl}');
    debugPrint('- Has Macros: ${meal.macros != null}');
    if (meal.macros != null) {
      debugPrint('- Protein: ${meal.macros!.proteinGrams}g');
      debugPrint('- Carbs: ${meal.macros!.carbsGrams}g');
      debugPrint('- Fat: ${meal.macros!.fatGrams}g');
      debugPrint('- Fiber: ${meal.macros!.fiberGrams}g');
    }
    debugPrint('- Is Low Fat: ${meal.isLowFat}');
    debugPrint('- Diet Type: ${meal.dietType}');
    
    // Get macro percentages if available
    double proteinPct = 0;
    double carbsPct = 0;
    double fatPct = 0;
    
    if (meal.macros != null) {
      proteinPct = meal.macros!.proteinPercentage * 100;
      carbsPct = meal.macros!.carbsPercentage * 100;
      fatPct = meal.macros!.fatPercentage * 100;
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calories
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.fire,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${meal.calories} calories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Macronutrients
          if (meal.macros != null) ...[
            const Text(
              'Macronutrients',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Progress bars for macros
            _buildMacroItem(
              context, 
              'Protein', 
              meal.macros!.proteinGrams, 
              proteinPct, 
              Colors.blue,
            ),
            
            _buildMacroItem(
              context, 
              'Carbs', 
              meal.macros!.carbsGrams, 
              carbsPct, 
              Colors.green,
            ),
            
            _buildMacroItem(
              context, 
              'Fat', 
              meal.macros!.fatGrams, 
              fatPct, 
              Colors.orange,
            ),
            
            // Macros summary text
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'P: ${proteinPct.toStringAsFixed(0)}% · C: ${carbsPct.toStringAsFixed(0)}% · F: ${fatPct.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ] else ...[
            Center(
              child: Text(
                'No detailed nutrition data available',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildMacroItem(
    BuildContext context, 
    String name, 
    double grams, 
    double percentage, 
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                '${grams.toStringAsFixed(1)}g',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          // Diet type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              meal.dietType,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Low fat badge if applicable
          if (meal.isLowFat)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Low Fat',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
} 