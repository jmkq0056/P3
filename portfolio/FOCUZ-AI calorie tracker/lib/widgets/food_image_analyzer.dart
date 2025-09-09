import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_image_service.dart';
import '../features/meals/meal_provider.dart';
import 'package:provider/provider.dart';
import '../services/cloudinary_service.dart';
import '../services/open_food_facts_service.dart';

class FoodImageAnalyzer extends StatefulWidget {
  final Function(FoodAnalysisResult)? onAnalysisResult;
  
  const FoodImageAnalyzer({
    super.key,
    this.onAnalysisResult,
  });

  @override
  FoodImageAnalyzerState createState() => FoodImageAnalyzerState();
}

class FoodImageAnalyzerState extends State<FoodImageAnalyzer> {
  final AIImageService _imageService = AIImageService();
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _dishNameController = TextEditingController();
  final TextEditingController _voiceNotesController = TextEditingController();
  final TextEditingController _preparationNotesController = TextEditingController();
  final TextEditingController _estimatedWeightController = TextEditingController();
  final TextEditingController _ingredientSearchController = TextEditingController();
  
  // Add GlobalKey for scrolling to advanced options
  final GlobalKey _advancedOptionsKey = GlobalKey();
  
  // Add ExpansionTileController for programmatic control
  late ExpansionTileController _advancedOptionsController;
  
  File? _selectedImage;
  List<File> _selectedImages = [];
  bool _isAnalyzing = false;
  FoodAnalysisResult? _analysisResult;
  String? _error;
  String? _detailedErrorInfo;
  int _retryCount = 0;
  
  // AI analysis preferences
  bool _isLowFat = false;
  String _dietType = 'Standard';
  final List<String> _dietTypes = ['Standard', 'Keto', 'Carnivore'];
  
  // Enhanced analysis features
  List<String> _includedIngredients = [];
  List<String> _excludedIngredients = [];
  String _cookingMethod = 'unknown';
  final List<String> _cookingMethods = [
    'unknown', 'grilled', 'fried', 'baked', 'boiled', 'steamed', 
    'roasted', 'sautéed', 'raw', 'microwaved'
  ];
  
  // Progressive analysis state
  bool _showAdvancedOptions = false;
  double _analysisProgress = 0.0;
  String _currentAnalysisStep = 'Ready to analyze';
  
  // Follow-up system
  List<String> _followUpQuestions = [];
  Map<String, String> _followUpAnswers = {};
  
  // Open Food Facts integration
  List<String> _suggestedIngredients = [];
  List<OpenFoodFactsProduct> _suggestedProducts = [];
  bool _isSearchingIngredients = false;
  
  @override
  void initState() {
    super.initState();
    _advancedOptionsController = ExpansionTileController();
  }
  
  @override
  void dispose() {
    _dishNameController.dispose();
    _voiceNotesController.dispose();
    _preparationNotesController.dispose();
    _estimatedWeightController.dispose();
    _ingredientSearchController.dispose();
    super.dispose();
  }
  
  Future<void> _takePicture() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        if (!_selectedImages.contains(_selectedImage)) {
          _selectedImages.add(_selectedImage!);
        }
        _analysisResult = null;
        _error = null;
        _detailedErrorInfo = null;
        _retryCount = 0;
        _analysisProgress = 0.0;
        _currentAnalysisStep = 'Starting analysis...';
      });
      
      _analyzeImage();
    }
  }
  
  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        if (!_selectedImages.contains(_selectedImage)) {
          _selectedImages.add(_selectedImage!);
        }
        _analysisResult = null;
        _error = null;
        _detailedErrorInfo = null;
        _retryCount = 0;
        _analysisProgress = 0.0;
        _currentAnalysisStep = 'Starting analysis...';
      });
      
      // Only analyze with AI - no manual upload option here
      _analyzeImage();
    }
  }
  
  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _isAnalyzing = true;
      _error = null;
      _detailedErrorInfo = null;
      _retryCount++;
      _analysisProgress = 0.1;
      _currentAnalysisStep = 'Processing image...';
    });
    
    try {
      setState(() {
        _analysisProgress = 0.3;
        _currentAnalysisStep = 'Analyzing food content...';
      });
      
      // Use enhanced analysis with all context - UPLOAD IMAGE DURING ANALYSIS
      final result = await _imageService.analyzeFoodImage(
        _selectedImage!,
        dishName: _dishNameController.text.isNotEmpty ? _dishNameController.text : null,
        isLowFat: _isLowFat,
        dietType: _dietType,
        shouldUploadImage: true, // UPLOAD IMAGE DURING ANALYSIS SO URL IS AVAILABLE
        includedIngredients: _includedIngredients,
        excludedIngredients: _excludedIngredients,
        cookingMethod: _cookingMethod,
        voiceNotes: _voiceNotesController.text.isNotEmpty ? _voiceNotesController.text : null,
        preparationNotes: _preparationNotesController.text.isNotEmpty ? _preparationNotesController.text : null,
        estimatedWeight: double.tryParse(_estimatedWeightController.text),
        analysisAttempt: _retryCount,
        previousImageUrls: _selectedImages.length > 1 ? [] : [], // Would be populated with uploaded URLs
      );
      
      setState(() {
        _analysisProgress = 0.8;
        _currentAnalysisStep = 'Finalizing analysis...';
      });
      
              if (result != null) {
          // Generate follow-up questions if needed
          if (result.needsImprovement) {
            _followUpQuestions = _imageService.generateFollowUpQuestions(result);
          }
          
          setState(() {
            _analysisResult = result;
            _isAnalyzing = false;
            _analysisProgress = 1.0;
            _currentAnalysisStep = 'Analysis complete!';
      });
      
      // Call the callback if provided
          if (widget.onAnalysisResult != null) {
        widget.onAnalysisResult!(_analysisResult!);
          }
        } else {
          throw AIAnalysisException('No analysis result received');
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _analysisProgress = 0.0;
        _currentAnalysisStep = 'Analysis failed';
        
        if (e is AIAnalysisException) {
          _error = e.message;
          
          // Store the detailed error for debugging
          if (e.responseBody != null) {
            _detailedErrorInfo = "Status: ${e.statusCode ?? 'Unknown'}\nResponse: ${e.responseBody}";
          }
        } else {
          _error = 'Error analyzing image: $e';
        }
      });
      
      // Log the error for debugging
      debugPrint('Error in food analysis: $_error');
      if (_detailedErrorInfo != null) {
        debugPrint('Detailed error info: $_detailedErrorInfo');
      }
    }
  }
  
  void _retryAnalysis() {
    if (_selectedImage == null) return;
    _analyzeImage();
  }
  
  // Add ingredient to included list
  void _addIngredient(String ingredient, bool isIncluded) {
    setState(() {
      if (isIncluded) {
        if (!_includedIngredients.contains(ingredient)) {
          _includedIngredients.add(ingredient);
        }
        _excludedIngredients.remove(ingredient);
      } else {
        if (!_excludedIngredients.contains(ingredient)) {
          _excludedIngredients.add(ingredient);
        }
        _includedIngredients.remove(ingredient);
      }
    });
  }
  
  // Remove ingredient from lists
  void _removeIngredient(String ingredient) {
    setState(() {
      _includedIngredients.remove(ingredient);
      _excludedIngredients.remove(ingredient);
    });
  }
  
  // Progressive analysis with multiple images
  Future<void> _progressiveAnalysis() async {
    if (_selectedImages.isEmpty) return;
    
    setState(() {
      _isAnalyzing = true;
      _error = null;
      _analysisProgress = 0.0;
      _currentAnalysisStep = 'Starting progressive analysis...';
    });
    
    try {
      // Progressive analysis will upload all images during processing
      final result = await _imageService.progressiveAnalysis(
        imageFiles: _selectedImages,
        dishName: _dishNameController.text.isNotEmpty ? _dishNameController.text : null,
        isLowFat: _isLowFat,
        dietType: _dietType,
        includedIngredients: _includedIngredients,
        excludedIngredients: _excludedIngredients,
        cookingMethod: _cookingMethod,
        voiceNotes: _voiceNotesController.text.isNotEmpty ? _voiceNotesController.text : null,
        preparationNotes: _preparationNotesController.text.isNotEmpty ? _preparationNotesController.text : null,
        estimatedWeight: double.tryParse(_estimatedWeightController.text),
      );
      
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
        _analysisProgress = 1.0;
        _currentAnalysisStep = 'Progressive analysis complete!';
        
        if (result != null && result.needsImprovement) {
          _followUpQuestions = _imageService.generateFollowUpQuestions(result);
        }
      });
      
      // Call the callback if provided
      if (widget.onAnalysisResult != null && _analysisResult != null) {
        widget.onAnalysisResult!(_analysisResult!);
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _analysisProgress = 0.0;
        _currentAnalysisStep = 'Progressive analysis failed';
        _error = 'Error in progressive analysis: $e';
      });
    }
  }
  
  // Answer follow-up question
  void _answerFollowUpQuestion(String question, String answer) {
    setState(() {
      _followUpAnswers[question] = answer;
    });
  }
  
  // Search ingredients using Open Food Facts
  Future<void> _searchIngredientsOpenFoodFacts(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestedIngredients.clear();
      });
      return;
    }
    
    setState(() {
      _isSearchingIngredients = true;
    });
    
    try {
      final ingredients = await _openFoodFactsService.searchIngredients(query, limit: 10);
      setState(() {
        _suggestedIngredients = ingredients;
        _isSearchingIngredients = false;
      });
    } catch (e) {
      debugPrint('Error searching ingredients: $e');
      setState(() {
        _isSearchingIngredients = false;
      });
    }
  }
  
  // Search products using Open Food Facts
  Future<void> _searchProductsOpenFoodFacts(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestedProducts.clear();
      });
      return;
    }
    
    try {
      final products = await _openFoodFactsService.searchProducts(query, limit: 5);
      setState(() {
        _suggestedProducts = products;
      });
    } catch (e) {
      debugPrint('Error searching products: $e');
    }
  }
  
  // Get suggested ingredients based on food name
  Future<void> _getSuggestedIngredientsForFood() async {
    final foodName = _dishNameController.text.trim();
    if (foodName.isEmpty) return;
    
    try {
      // Search for products similar to the food name
      final products = await _openFoodFactsService.searchProducts(foodName, limit: 3);
      final suggestions = <String>{};
      
      for (var product in products) {
        suggestions.addAll(product.ingredients.take(5));
      }
      
      setState(() {
        _suggestedIngredients = suggestions.toList();
      });
    } catch (e) {
      debugPrint('Error getting suggested ingredients: $e');
    }
  }
  
  // Add ingredient from Open Food Facts
  void _addIngredientFromOpenFoodFacts(String ingredient) {
    _addIngredient(ingredient, true);
    _ingredientSearchController.clear();
    setState(() {
      _suggestedIngredients.clear();
    });
  }
  
  // Use product data from Open Food Facts
  void _useProductData(OpenFoodFactsProduct product) {
    setState(() {
      // Set food name if not already set
      if (_dishNameController.text.isEmpty) {
        _dishNameController.text = product.name;
      }
      
      // Add all product ingredients
      for (var ingredient in product.ingredients) {
        if (!_includedIngredients.contains(ingredient)) {
          _includedIngredients.add(ingredient);
        }
      }
      
      // Set estimated weight from serving size if available
      if (product.servingSize?.isNotEmpty ?? false) {
        final servingSize = product.servingSize!;
        final weight = RegExp(r'(\d+)').firstMatch(servingSize)?.group(1);
        if (weight != null && _estimatedWeightController.text.isEmpty) {
          _estimatedWeightController.text = weight;
        }
      }
      
      _suggestedProducts.clear();
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ingredients from ${product.name}'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // Enhance current analysis with Open Food Facts data
  Future<void> _enhanceWithOpenFoodFacts() async {
    if (_analysisResult == null) return;
    
    setState(() {
      _isAnalyzing = true;
      _currentAnalysisStep = 'Enhancing with Open Food Facts...';
      _analysisProgress = 0.5;
    });
    
    try {
      final enhancedResult = await _imageService.enhanceWithOpenFoodFacts(_analysisResult!);
      
      setState(() {
        _analysisResult = enhancedResult;
        _isAnalyzing = false;
        _analysisProgress = 1.0;
        _currentAnalysisStep = 'Enhanced with Open Food Facts!';
        
        // Update follow-up questions if needed
        if (enhancedResult.needsImprovement) {
          _followUpQuestions = _imageService.generateFollowUpQuestions(enhancedResult);
        } else {
          _followUpQuestions.clear();
        }
      });
      
      // Call the callback with enhanced result
      if (widget.onAnalysisResult != null) {
        widget.onAnalysisResult!(enhancedResult);
      }
      
      // Show enhancement message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Analysis enhanced! Confidence: ${(enhancedResult.confidenceScore * 100).toInt()}%, '
            'Ingredients: ${enhancedResult.detectedIngredients.length}'
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _analysisProgress = 0.0;
        _currentAnalysisStep = 'Enhancement failed';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to enhance analysis: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  void _saveToMeal() async {
    if (_analysisResult == null) return;
    
    try {
      // Image is already uploaded during analysis, use the URL from the result
      final imageUrl = _analysisResult!.imageUrl;
      
      debugPrint('SAVING MEAL FROM AI ANALYZER:');
      debugPrint('- Food Name: ${_analysisResult!.foodName}');
      debugPrint('- Image URL: $imageUrl');
      debugPrint('- Calories: ${_analysisResult!.calories}');
      debugPrint('- Is Low Fat: ${_analysisResult!.isLowFat}');
      debugPrint('- Diet Type: ${_analysisResult!.dietType}');
      
      // Add to meal database using Provider with the image URL from analysis
      final provider = Provider.of<MealProvider>(context, listen: false);
      provider.logMeal(
        _analysisResult!.foodName, 
        _analysisResult!.calories,
        protein: _analysisResult!.protein,
        fat: _analysisResult!.fat,
        carbs: _analysisResult!.carbs,
        isLowFat: _analysisResult!.isLowFat,
        dietType: _analysisResult!.dietType,
        imageUrl: imageUrl, // Use the image URL from analysis result
      );
      
      // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Text('Added ${_analysisResult!.foodName} to meals'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
      
      // Reset the form state after successful save
      setState(() {
        _selectedImage = null;
        _analysisResult = null;
        _error = null;
        _detailedErrorInfo = null;
        _retryCount = 0;
        _dishNameController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save meal: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'AI Food Analysis',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Divider line
            Container(
              height: 1,
              width: double.infinity,
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            
            // Dish name input field
            TextField(
              controller: _dishNameController,
              decoration: InputDecoration(
                labelText: 'Dish Name (Optional)',
                hintText: 'E.g., Chicken Salad, Pizza, etc.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.restaurant_menu),
              ),
              onChanged: (value) {
                // Search for similar products when dish name changes
                Future.delayed(const Duration(milliseconds: 1000), () {
                  if (_dishNameController.text == value && value.isNotEmpty) {
                    _searchProductsOpenFoodFacts(value);
                    _getSuggestedIngredientsForFood();
                  }
                });
              },
            ),
            
            // Open Food Facts product suggestions
            if (_suggestedProducts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.store, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Similar Products from Open Food Facts',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(_suggestedProducts.take(3).map((product) => _buildProductSuggestion(product))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            
            // Analysis Progress Indicator
            if (_isAnalyzing || _analysisProgress > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          _currentAnalysisStep,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _analysisProgress,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_analysisProgress * 100).toInt()}% complete',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Advanced Options Toggle
            Card(
              key: _advancedOptionsKey,
              child: ExpansionTile(
                controller: _advancedOptionsController,
                onExpansionChanged: (expanded) {
                  setState(() {
                    _showAdvancedOptions = expanded;
                  });
                },
                title: const Text('Advanced Analysis Options'),
                leading: const Icon(Icons.tune),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Voice Notes Section
                        TextField(
                          controller: _voiceNotesController,
                          decoration: const InputDecoration(
                            labelText: 'Voice Notes / Additional Info',
                            hintText: 'e.g., "Grilled with olive oil", "Large restaurant portion"',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.mic),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        
                        // Preparation Notes
                        TextField(
                          controller: _preparationNotesController,
                          decoration: const InputDecoration(
                            labelText: 'Preparation Details',
                            hintText: 'Cooking method, ingredients, seasonings...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        
                        // Estimated Weight
                        TextField(
                          controller: _estimatedWeightController,
                          decoration: const InputDecoration(
                            labelText: 'Estimated Weight (grams)',
                            hintText: 'Optional weight estimate',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.scale),
                            suffixText: 'g',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        
                        // Cooking Method Dropdown
                        DropdownButtonFormField<String>(
                          value: _cookingMethod,
                          decoration: const InputDecoration(
                            labelText: 'Cooking Method',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.whatshot),
                          ),
                                                     items: _cookingMethods.map((method) {
                             return DropdownMenuItem(
                               value: method,
                               child: Text(_capitalize(method)),
                             );
                           }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _cookingMethod = value ?? 'unknown';
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Ingredient Management
                        _buildIngredientManagement(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // AI Preferences Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI Analysis Preferences',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Low fat option as a custom switch
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isLowFat = !_isLowFat;
                        
                        // Update analysis result if already exists
                        if (_analysisResult != null) {
                          _analysisResult = FoodAnalysisResult(
                            foodName: _analysisResult!.foodName,
                            calories: _analysisResult!.calories,
                            protein: _analysisResult!.protein,
                            fat: _analysisResult!.fat,
                            carbs: _analysisResult!.carbs,
                            isLowFat: _isLowFat,
                            dietType: _dietType,
                          );
                          
                          // Call the callback if provided
                          if (widget.onAnalysisResult != null) {
                            widget.onAnalysisResult!(_analysisResult!);
                          }
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isLowFat 
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.1) 
                                : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _isLowFat ? Icons.check_circle : Icons.circle_outlined,
                              color: _isLowFat 
                                ? Theme.of(context).colorScheme.primary 
                                : Colors.grey,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Analyze as Low Fat',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Focus on foods with under 10% fat content',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Diet Type selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.restaurant_menu,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Dietary Approach',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _dietType,
                            isExpanded: true,
                            icon: Icon(
                              Icons.arrow_drop_down_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            elevation: 2,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: 16,
                            ),
                            dropdownColor: Theme.of(context).colorScheme.surface,
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
                                  
                                  // Update analysis result if already exists
                                  if (_analysisResult != null) {
                                    _analysisResult = FoodAnalysisResult(
                                      foodName: _analysisResult!.foodName,
                                      calories: _analysisResult!.calories,
                                      protein: _analysisResult!.protein,
                                      fat: _analysisResult!.fat,
                                      carbs: _analysisResult!.carbs,
                                      isLowFat: _isLowFat,
                                      dietType: _dietType,
                                    );
                                    
                                    // Call the callback if provided
                                    if (widget.onAnalysisResult != null) {
                                      widget.onAnalysisResult!(_analysisResult!);
                                    }
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Image preview
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedImage!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.robot,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Take a picture for AI analysis',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Our AI will analyze your food and provide nutrition information',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Loading state
            if (_isAnalyzing)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'Analyzing food${_retryCount > 1 ? ' (Attempt $_retryCount)' : ''}...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            
            // Analysis result
            if (_analysisResult != null && !_isAnalyzing)
              _buildAnalysisResult(),
            
            // Error state
            if (_error != null && !_isAnalyzing)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.red.withOpacity(0.05),
                          Colors.red.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const FaIcon(
                                FontAwesomeIcons.circleExclamation,
                                color: Colors.red,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _error!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        // Show detailed error info for debugging if available
                        if (_detailedErrorInfo != null) ...[
                          const SizedBox(height: 8),
                          ExpansionTile(
                            title: const Text('Technical Details (for debugging)'),
                            initiallyExpanded: false,
                            tilePadding: EdgeInsets.zero,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.grey.withOpacity(0.1),
                                width: double.infinity,
                                child: SelectableText(
                                  _detailedErrorInfo!,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _retryAnalysis,
                      icon: const FaIcon(FontAwesomeIcons.arrowRotateRight, size: 16),
                      label: const Text('Retry AI Analysis'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 16),
            
            // Action buttons - Enhanced with progressive analysis
            if (_selectedImages.length > 1) ...[
              // Progressive analysis button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _progressiveAnalysis,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: Text('Progressive Analysis (${_selectedImages.length} images)'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _takePicture,
                    icon: const FaIcon(FontAwesomeIcons.camera, size: 18),
                    label: Text(_selectedImages.isEmpty ? 'Camera' : 'Add Photo'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _pickImage,
                    icon: const FaIcon(FontAwesomeIcons.image, size: 18),
                    label: Text(_selectedImages.isEmpty ? 'Gallery' : 'Add Image'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
            
            // Clear images button if multiple selected
            if (_selectedImages.length > 1) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedImages.clear();
                    _selectedImage = null;
                    _analysisResult = null;
                    _followUpQuestions.clear();
                    _analysisProgress = 0.0;
                  });
                },
                icon: const Icon(Icons.clear_all, color: Colors.red),
                label: const Text('Clear All Images', style: TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildAnalysisResult() {
    if (_analysisResult == null) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                'AI Analysis Result',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  // Confidence indicator
                  Row(
                    children: [
                      Icon(
                        _analysisResult!.confidenceScore >= 0.8 
                          ? Icons.check_circle 
                          : _analysisResult!.confidenceScore >= 0.6 
                            ? Icons.warning 
                            : Icons.error,
                        size: 16,
                        color: _analysisResult!.confidenceScore >= 0.8 
                          ? Colors.green 
                          : _analysisResult!.confidenceScore >= 0.6 
                            ? Colors.orange 
                            : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Confidence: ${(_analysisResult!.confidenceScore * 100).toInt()}% (${_analysisResult!.analysisQuality})',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _analysisResult!.confidenceScore >= 0.8 
                            ? Colors.green 
                            : _analysisResult!.confidenceScore >= 0.6 
                              ? Colors.orange 
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Food name with special styling
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identified Food',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _analysisResult!.foodName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Calorie information with prominent display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_analysisResult!.calories}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'kcal',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Display diet type and low fat status in a modern chip-like design
          Row(
            children: [
              if (_analysisResult!.dietType != null && _analysisResult!.dietType != 'Standard')
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _analysisResult!.dietType!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_analysisResult!.isLowFat != null && _analysisResult!.isLowFat!)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Low Fat',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Macro breakdown as percentages with an AI-styled header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.pie_chart,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Macronutrient Distribution',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Enhanced macro bars
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildMacroBar(
                  'Protein', 
                  _analysisResult!.proteinPercentage, 
                  Colors.green.shade500
                ),
                const SizedBox(height: 10),
                _buildMacroBar(
                  'Carbs', 
                  _analysisResult!.carbsPercentage, 
                  Colors.amber.shade600
                ),
                const SizedBox(height: 10),
                _buildMacroBar(
                  'Fat', 
                  _analysisResult!.fatPercentage, 
                  Colors.redAccent.shade200
                ),
              ],
            ),
          ),
          
          // Follow-up questions if analysis needs improvement
          if (_followUpQuestions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Improve Analysis Accuracy',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'To improve accuracy, could you help with these questions?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  ..._followUpQuestions.map((question) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: Colors.orange.shade700)),
                        Expanded(child: Text(question)),
                      ],
                    ),
                  )).toList(),
                  const SizedBox(height: 12),
                  // Wrap buttons to prevent overflow
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // Expand the advanced options using the controller
                          _advancedOptionsController.expand();
                          
                          setState(() {
                            _showAdvancedOptions = true;
                          });
                          
                          // Scroll to advanced options section
                          Future.delayed(const Duration(milliseconds: 300), () {
                            final context = _advancedOptionsKey.currentContext;
                            if (context != null) {
                              Scrollable.ensureVisible(
                                context,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            }
                          });
                          
                          // Show feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.tune, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Advanced options expanded above'),
                                ],
                              ),
                              backgroundColor: Colors.orange,
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.tune, size: 16),
                        label: const Text('More Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _enhanceWithOpenFoodFacts,
                        icon: _isAnalyzing 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.auto_fix_high, size: 16),
                        label: Text(_isAnalyzing ? 'Enhancing...' : 'Enhance'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          
          // Analysis metadata
          if (_analysisResult!.detectedIngredients.isNotEmpty || 
              _analysisResult!.cookingMethod != 'unknown' ||
              _analysisResult!.estimatedWeight > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analysis Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_analysisResult!.detectedIngredients.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.inventory, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Detected: ${_analysisResult!.detectedIngredients.join(', ')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_analysisResult!.cookingMethod != 'unknown') ...[
                    Row(
                      children: [
                        Icon(Icons.whatshot, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Cooking: ${_capitalize(_analysisResult!.cookingMethod)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_analysisResult!.estimatedWeight > 0) ...[
                    Row(
                      children: [
                        Icon(Icons.scale, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Weight: ${_analysisResult!.estimatedWeight.toInt()}g',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          // "Powered by AI" badge
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.smart_toy,
                    size: 14,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade300
                        : Colors.grey.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Powered by AI',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMacroBar(String name, double percentage, Color color) {
    final percentInt = (percentage * 100).toInt();
    final nutrientKey = name.toLowerCase();
    final confidence = _analysisResult?.getNutrientConfidence(nutrientKey) ?? 0.7;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 4),
                // Confidence indicator
                Icon(
                  confidence >= 0.8 
                    ? Icons.check_circle 
                    : confidence >= 0.6 
                      ? Icons.warning 
                      : Icons.error,
                  size: 12,
                  color: confidence >= 0.8 
                    ? Colors.green 
                    : confidence >= 0.6 
                      ? Colors.orange 
                      : Colors.red,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$percentInt%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '${(confidence * 100).toInt()}% conf.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Background track
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? Colors.grey.shade700.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Progress indicator with animated gradient
            Container(
              height: 10,
              width: MediaQuery.of(context).size.width * 0.7 * percentage,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    color.withOpacity(0.7),
                    color,
                  ],
                ),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            // Confidence overlay (subtle pattern for low confidence)
            if (confidence < 0.8)
              Container(
                height: 10,
                width: MediaQuery.of(context).size.width * 0.7 * percentage,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: isDarkMode 
                      ? Colors.black.withOpacity(0.2)
                      : Colors.white.withOpacity(0.3),
                ),
              ),
          ],
        ),
      ],
    );
  }
  
  // Helper method to capitalize strings
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  
  // Build ingredient management section
  Widget _buildIngredientManagement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredient Management',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Detected ingredients from AI
        if (_analysisResult?.detectedIngredients.isNotEmpty ?? false) ...[
          Text(
            'AI Detected Ingredients:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _analysisResult!.detectedIngredients.map((ingredient) {
              final isIncluded = _includedIngredients.contains(ingredient);
              final isExcluded = _excludedIngredients.contains(ingredient);
              
              return FilterChip(
                label: Text(ingredient),
                selected: isIncluded,
                onSelected: (selected) {
                  _addIngredient(ingredient, selected);
                },
                backgroundColor: isExcluded ? Colors.red.withOpacity(0.1) : null,
                selectedColor: Colors.green.withOpacity(0.3),
                avatar: isExcluded 
                  ? const Icon(Icons.close, size: 16, color: Colors.red)
                  : isIncluded 
                    ? const Icon(Icons.check, size: 16, color: Colors.green)
                    : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        // Enhanced ingredient search with Open Food Facts
        TextField(
          controller: _ingredientSearchController,
          decoration: InputDecoration(
            labelText: 'Search Ingredients',
            hintText: 'Search Open Food Facts database...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isSearchingIngredients 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          ),
          onChanged: (value) {
            // Debounce search
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_ingredientSearchController.text == value) {
                _searchIngredientsOpenFoodFacts(value);
              }
            });
          },
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              _addIngredient(value.trim(), true);
              _ingredientSearchController.clear();
            }
          },
        ),
        
        // Open Food Facts ingredient suggestions
        if (_suggestedIngredients.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 150),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedIngredients.map((ingredient) {
                  return ActionChip(
                    label: Text(ingredient),
                    onPressed: () => _addIngredientFromOpenFoodFacts(ingredient),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    avatar: const Icon(Icons.add, size: 16),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        
        // Included ingredients
        if (_includedIngredients.isNotEmpty) ...[
          Text(
            'Included Ingredients:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _includedIngredients.map((ingredient) {
              return Chip(
                label: Text(ingredient),
                backgroundColor: Colors.green.withOpacity(0.1),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeIngredient(ingredient),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        
        // Excluded ingredients
        if (_excludedIngredients.isNotEmpty) ...[
          Text(
            'Excluded Ingredients:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _excludedIngredients.map((ingredient) {
              return Chip(
                label: Text(ingredient),
                backgroundColor: Colors.red.withOpacity(0.1),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeIngredient(ingredient),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
  
  // Build product suggestion widget
  Widget _buildProductSuggestion(OpenFoodFactsProduct product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Product image or placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(6),
            ),
            child: product.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    product.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.fastfood, color: Colors.grey.shade600);
                    },
                  ),
                )
              : Icon(Icons.fastfood, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 12),
          
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.brand?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.brand!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (product.ingredients.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${product.ingredients.length} ingredients',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Use button
          ElevatedButton(
            onPressed: () => _useProductData(product),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Use',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
} 