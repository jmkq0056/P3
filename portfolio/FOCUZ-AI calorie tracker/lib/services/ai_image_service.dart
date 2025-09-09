import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import './cloudinary_service.dart';
import './open_food_facts_service.dart';

class FoodAnalysisResult {
  // Core nutrition data
  final String foodName;
  final int calories;
  final double protein;
  final double fat;
  final double carbs;
  final double fiber;
  final double estimatedWeight; // NEW: Total food weight in grams
  
  // Calculated values
  final double proteinPercentage;
  final double carbsPercentage;
  final double fatPercentage;
  
  // Analysis metadata
  final double confidenceScore; // NEW: 0.0 to 1.0
  final bool requiresFollowUp; // NEW: AI determined
  final List<String> followUpQuestions; // NEW: Dynamic questions
  final List<String> detectedIngredients; // NEW: AI detected
  final String cookingMethod; // NEW: grilled, fried, etc.
  
  // User preferences
  final bool isLowFat;
  final String dietType;
  final String? imageUrl;
  
  // Multi-image support
  final List<String> imageUrls; // NEW: Multiple analysis images
  final int analysisAttempt; // NEW: Track attempt number
  
  // Voice and text integration
  final String? voiceNotes; // NEW: Voice input from user
  final String? preparationNotes; // NEW: Text notes about preparation
  final Map<String, double> nutritionConfidence; // NEW: Per-nutrient confidence

  FoodAnalysisResult({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    this.fiber = 0.0,
    this.estimatedWeight = 0.0,
    double? proteinPercentage,
    double? carbsPercentage,
    double? fatPercentage,
    this.confidenceScore = 0.7,
    this.requiresFollowUp = false,
    this.followUpQuestions = const [],
    this.detectedIngredients = const [],
    this.cookingMethod = 'unknown',
    this.isLowFat = false,
    this.dietType = 'Standard',
    this.imageUrl,
    this.imageUrls = const [],
    this.analysisAttempt = 1,
    this.voiceNotes,
    this.preparationNotes,
    this.nutritionConfidence = const {},
  }) : 
    this.proteinPercentage = proteinPercentage ?? _calculateProteinPercentage(protein, fat, carbs),
    this.carbsPercentage = carbsPercentage ?? _calculateCarbsPercentage(protein, fat, carbs),
    this.fatPercentage = fatPercentage ?? _calculateFatPercentage(protein, fat, carbs);

  static double _calculateProteinPercentage(double protein, double fat, double carbs) {
    double proteinCalories = protein * 4;
    double carbsCalories = carbs * 4;
    double fatCalories = fat * 9;
    double totalCalories = proteinCalories + carbsCalories + fatCalories;
    
    return totalCalories > 0 ? proteinCalories / totalCalories : 0.0;
  }
  
  static double _calculateCarbsPercentage(double protein, double fat, double carbs) {
    double proteinCalories = protein * 4;
    double carbsCalories = carbs * 4;
    double fatCalories = fat * 9;
    double totalCalories = proteinCalories + carbsCalories + fatCalories;
    
    return totalCalories > 0 ? carbsCalories / totalCalories : 0.0;
  }
  
  static double _calculateFatPercentage(double protein, double fat, double carbs) {
    double proteinCalories = protein * 4;
    double carbsCalories = carbs * 4;
    double fatCalories = fat * 9;
    double totalCalories = proteinCalories + carbsCalories + fatCalories;
    
    return totalCalories > 0 ? fatCalories / totalCalories : 0.0;
  }

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    final proteinGrams = _parseDoubleValue(json['protein_g']);
    final carbsGrams = _parseDoubleValue(json['carbs_g']);
    final fatGrams = _parseDoubleValue(json['fat_g']);
    final fiberGrams = _parseDoubleValue(json['fiber_g']);
    final estimatedWeight = _parseDoubleValue(json['estimated_weight_g']);
    
    // Parse confidence scores
    final confidenceScore = _parseDoubleValue(json['confidence_score']) ?? 0.7;
    final nutritionConfidence = <String, double>{};
    if (json['nutrition_confidence'] != null) {
      final confMap = json['nutrition_confidence'] as Map<String, dynamic>;
      confMap.forEach((key, value) {
        nutritionConfidence[key] = _parseDoubleValue(value) ?? 0.7;
      });
    }
    
    // Parse detected ingredients
    final detectedIngredients = <String>[];
    if (json['detected_ingredients'] != null) {
      final ingredients = json['detected_ingredients'];
      if (ingredients is List) {
        detectedIngredients.addAll(ingredients.cast<String>());
      } else if (ingredients is String) {
        detectedIngredients.addAll(ingredients.split(',').map((s) => s.trim()));
      }
    }
    
    // Parse follow-up questions
    final followUpQuestions = <String>[];
    if (json['follow_up_questions'] != null) {
      final questions = json['follow_up_questions'];
      if (questions is List) {
        followUpQuestions.addAll(questions.cast<String>());
      }
    }
    
    // Parse image URLs
    final imageUrls = <String>[];
    if (json['image_urls'] != null) {
      final urls = json['image_urls'];
      if (urls is List) {
        imageUrls.addAll(urls.cast<String>());
      }
    }
    
    return FoodAnalysisResult(
      foodName: json['food'] ?? 'Unknown Food',
      calories: _parseIntValue(json['kcal']),
      protein: proteinGrams,
      fat: fatGrams,
      carbs: carbsGrams,
      fiber: fiberGrams,
      estimatedWeight: estimatedWeight,
      confidenceScore: confidenceScore,
      requiresFollowUp: json['requires_follow_up'] ?? false,
      followUpQuestions: followUpQuestions,
      detectedIngredients: detectedIngredients,
      cookingMethod: json['cooking_method'] ?? 'unknown',
      imageUrl: json['imageUrl'],
      imageUrls: imageUrls,
      analysisAttempt: _parseIntValue(json['analysis_attempt']) ?? 1,
      voiceNotes: json['voice_notes'],
      preparationNotes: json['preparation_notes'],
      nutritionConfidence: nutritionConfidence,
    );
  }

  static int _parseIntValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      try {
        return double.parse(value).round();
      } catch (_) {
        return 0;
      }
    }
    return 0;
  }

  static double _parseDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'food': foodName,
      'kcal': calories,
      'protein_g': protein,
      'fat_g': fat,
      'carbs_g': carbs,
      'fiber_g': fiber,
      'estimated_weight_g': estimatedWeight,
      'protein_percentage': proteinPercentage,
      'carbs_percentage': carbsPercentage,
      'fat_percentage': fatPercentage,
      'confidence_score': confidenceScore,
      'requires_follow_up': requiresFollowUp,
      'follow_up_questions': followUpQuestions,
      'detected_ingredients': detectedIngredients,
      'cooking_method': cookingMethod,
      'imageUrl': imageUrl,
      'image_urls': imageUrls,
      'analysis_attempt': analysisAttempt,
      'voice_notes': voiceNotes,
      'preparation_notes': preparationNotes,
      'nutrition_confidence': nutritionConfidence,
    };
  }
  
  FoodAnalysisResult copyWith({
    String? foodName,
    int? calories,
    double? protein,
    double? fat,
    double? carbs,
    double? fiber,
    double? estimatedWeight,
    double? proteinPercentage,
    double? carbsPercentage,
    double? fatPercentage,
    double? confidenceScore,
    bool? requiresFollowUp,
    List<String>? followUpQuestions,
    List<String>? detectedIngredients,
    String? cookingMethod,
    bool? isLowFat,
    String? dietType,
    String? imageUrl,
    List<String>? imageUrls,
    int? analysisAttempt,
    String? voiceNotes,
    String? preparationNotes,
    Map<String, double>? nutritionConfidence,
  }) {
    return FoodAnalysisResult(
      foodName: foodName ?? this.foodName,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      fiber: fiber ?? this.fiber,
      estimatedWeight: estimatedWeight ?? this.estimatedWeight,
      proteinPercentage: proteinPercentage,
      carbsPercentage: carbsPercentage,
      fatPercentage: fatPercentage,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      requiresFollowUp: requiresFollowUp ?? this.requiresFollowUp,
      followUpQuestions: followUpQuestions ?? this.followUpQuestions,
      detectedIngredients: detectedIngredients ?? this.detectedIngredients,
      cookingMethod: cookingMethod ?? this.cookingMethod,
      isLowFat: isLowFat ?? this.isLowFat,
      dietType: dietType ?? this.dietType,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      analysisAttempt: analysisAttempt ?? this.analysisAttempt,
      voiceNotes: voiceNotes ?? this.voiceNotes,
      preparationNotes: preparationNotes ?? this.preparationNotes,
      nutritionConfidence: nutritionConfidence ?? this.nutritionConfidence,
    );
  }
  
  // Helper method to get confidence for a specific nutrient
  double getNutrientConfidence(String nutrient) {
    return nutritionConfidence[nutrient] ?? confidenceScore;
  }
  
  // Helper method to check if analysis needs improvement
  bool get needsImprovement {
    return confidenceScore < 0.8 || requiresFollowUp;
  }
  
  // Helper method to get overall analysis quality
  String get analysisQuality {
    if (confidenceScore >= 0.9) return 'Excellent';
    if (confidenceScore >= 0.8) return 'Good';
    if (confidenceScore >= 0.7) return 'Fair';
    return 'Poor';
  }
}

class AIAnalysisException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  AIAnalysisException(this.message, {this.statusCode, this.responseBody});

  @override
  String toString() {
    String result = message;
    if (statusCode != null) {
      result += ' (Status: $statusCode)';
    }
    return result;
  }
}

class AIImageService {
  static final AIImageService _instance = AIImageService._internal();
  factory AIImageService() => _instance;
  
  AIImageService._internal();
  
  final String _apiKey = 'REMOVED_FOR_SECURITY';
  final OpenFoodFactsService _openFoodFactsService = OpenFoodFactsService();
  
  // Enhanced analysis with multi-modal support
  Future<FoodAnalysisResult?> analyzeFoodImage(File imageFile, {
    String? dishName,
    bool isLowFat = false,
    String dietType = 'Standard',
    bool shouldUploadImage = true,
    List<String>? includedIngredients,
    List<String>? excludedIngredients,
    String? cookingMethod,
    String? voiceNotes,
    String? preparationNotes,
    double? estimatedWeight,
    int analysisAttempt = 1,
    List<String> previousImageUrls = const [],
  }) async {
    try {
      if (!await imageFile.exists()) {
        throw AIAnalysisException('Image file does not exist');
      }
      
      final fileSize = await imageFile.length();
      if (fileSize <= 0) {
        throw AIAnalysisException('Image file is empty');
      }
      
      if (fileSize > 20 * 1024 * 1024) {
        throw AIAnalysisException('Image file is too large (max 20MB)');
      }
      
      String? imageUrl;
      
      if (shouldUploadImage) {
        final cloudinaryService = CloudinaryService();
        
        try {
          debugPrint('AI ANALYSIS: Starting image upload to Cloudinary');
          debugPrint('AI ANALYSIS: Image file path: ${imageFile.path}');
          debugPrint('AI ANALYSIS: Image file size: ${await imageFile.length()} bytes');
          
          imageUrl = await cloudinaryService.uploadImage(imageFile, imageType: 'meal');
          debugPrint('AI ANALYSIS: Image uploaded successfully to Cloudinary: $imageUrl');
        } catch (e) {
          debugPrint('AI ANALYSIS: ERROR uploading image to Cloudinary: $e');
          throw AIAnalysisException('Failed to upload image to Cloudinary: $e');
        }
      } else {
        debugPrint('AI ANALYSIS: Skipping image upload (shouldUploadImage: false)');
      }
      
      List<int> imageBytes;
      try {
        imageBytes = await imageFile.readAsBytes();
      } catch (e) {
        throw AIAnalysisException('Failed to read image file: $e');
      }
      
      final String base64Image = base64Encode(imageBytes);
      
      // Generate dynamic, context-aware prompt
      String prompt = _generateAnalysisPrompt(
        dishName: dishName,
        isLowFat: isLowFat,
        dietType: dietType,
        includedIngredients: includedIngredients,
        excludedIngredients: excludedIngredients,
        cookingMethod: cookingMethod,
        voiceNotes: voiceNotes,
        preparationNotes: preparationNotes,
        estimatedWeight: estimatedWeight,
        analysisAttempt: analysisAttempt,
        previousImageUrls: previousImageUrls,
      );
      
      debugPrint('Preparing OpenAI request with prompt: $prompt');
      
      final payload = {
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': prompt
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image'
                }
              }
            ]
          }
        ],
        'max_tokens': 300
      };
      
      http.Response response;
      try {
        debugPrint('Sending request to OpenAI API');
        response = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        );
        
        debugPrint('Received response with status: ${response.statusCode}');
      } catch (e) {
        throw AIAnalysisException('Network error when contacting OpenAI API: $e');
      }
      
      if (response.statusCode != 200) {
        Map<String, dynamic>? errorJson;
        String errorMessage = 'API request failed';
        
        try {
          errorJson = jsonDecode(response.body) as Map<String, dynamic>;
          errorMessage = errorJson['error']['message'] ?? 'Unknown API error';
        } catch (_) {
          errorMessage = 'Status code: ${response.statusCode}, Body: ${response.body}';
        }
        
        throw AIAnalysisException(
          'OpenAI API error: $errorMessage',
          statusCode: response.statusCode,
          responseBody: response.body,
        );
      }
      
      Map<String, dynamic> jsonResponse;
      try {
        jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw AIAnalysisException('Failed to parse API response: $e', responseBody: response.body);
      }
      
      if (jsonResponse['choices'] == null || 
          jsonResponse['choices'].isEmpty ||
          jsonResponse['choices'][0]['message'] == null ||
          jsonResponse['choices'][0]['message']['content'] == null) {
        throw AIAnalysisException(
          'Invalid API response format', 
          responseBody: response.body,
        );
      }
      
      String content = jsonResponse['choices'][0]['message']['content'] as String;
      content = content.trim();
      
      if (content.contains('```json')) {
        content = content.split('```json')[1].split('```')[0].trim();
      } else if (content.contains('```')) {
        content = content.split('```')[1].split('```')[0].trim();
      }
      
      Map<String, dynamic> nutritionData;
      try {
        nutritionData = jsonDecode(content) as Map<String, dynamic>;
      } catch (e) {
        throw AIAnalysisException('Failed to parse nutrition data from response: $e', responseBody: content);
      }
      
      final result = FoodAnalysisResult.fromJson(nutritionData);
      
      // Create image URLs list
      List<String> allImageUrls = List.from(previousImageUrls);
      if (imageUrl != null) {
        allImageUrls.add(imageUrl);
      }
      
      debugPrint('AI ANALYSIS: Creating final result with:');
      debugPrint('AI ANALYSIS: - Food Name: ${result.foodName}');
      debugPrint('AI ANALYSIS: - Image URL: $imageUrl');
      debugPrint('AI ANALYSIS: - All Image URLs: $allImageUrls');
      debugPrint('AI ANALYSIS: - Is Low Fat: $isLowFat');
      debugPrint('AI ANALYSIS: - Diet Type: $dietType');
      
      final baseResult = result.copyWith(
        isLowFat: isLowFat,
        dietType: dietType,
        imageUrl: imageUrl,
        imageUrls: allImageUrls,
        analysisAttempt: analysisAttempt,
        voiceNotes: voiceNotes,
        preparationNotes: preparationNotes,
      );
      
      // Apply dish name if provided
      final namedResult = dishName != null && dishName.isNotEmpty 
        ? baseResult.copyWith(foodName: dishName)
        : baseResult;
      
      debugPrint('AI ANALYSIS: Final result before Open Food Facts enhancement:');
      debugPrint('AI ANALYSIS: - Final Food Name: ${namedResult.foodName}');
      debugPrint('AI ANALYSIS: - Final Image URL: ${namedResult.imageUrl}');
      
      // Enhance with Open Food Facts data
      final enhancedResult = await enhanceWithOpenFoodFacts(namedResult);
      
      debugPrint('AI ANALYSIS: Enhanced result:');
      debugPrint('AI ANALYSIS: - Enhanced Food Name: ${enhancedResult.foodName}');
      debugPrint('AI ANALYSIS: - Enhanced Image URL: ${enhancedResult.imageUrl}');
      
      return enhancedResult;
    } catch (e) {
      if (e is AIAnalysisException) {
        rethrow;
      }
      throw AIAnalysisException('General error analyzing food image: $e');
    }
  }
  
  // Generate context-aware analysis prompt
  String _generateAnalysisPrompt({
    String? dishName,
    bool isLowFat = false,
    String dietType = 'Standard',
    List<String>? includedIngredients,
    List<String>? excludedIngredients,
    String? cookingMethod,
    String? voiceNotes,
    String? preparationNotes,
    double? estimatedWeight,
    int analysisAttempt = 1,
    List<String> previousImageUrls = const [],
  }) {
    StringBuffer prompt = StringBuffer();
    
    // Base instruction
    if (analysisAttempt > 1 && previousImageUrls.isNotEmpty) {
      prompt.write('This is analysis attempt #$analysisAttempt. Previous images have been analyzed. ');
      prompt.write('Please provide a refined analysis with improved accuracy. ');
    }
    
    if (dishName != null && dishName.isNotEmpty) {
      prompt.write('This is identified as: $dishName. ');
    } else {
      prompt.write('Identify this food item. ');
    }
    
    // Context from voice notes
    if (voiceNotes != null && voiceNotes.isNotEmpty) {
      prompt.write('User notes: "$voiceNotes". ');
    }
    
    // Context from preparation notes
    if (preparationNotes != null && preparationNotes.isNotEmpty) {
      prompt.write('Preparation details: "$preparationNotes". ');
    }
    
    // Cooking method context
    if (cookingMethod != null && cookingMethod != 'unknown') {
      prompt.write('Cooking method: $cookingMethod. ');
    }
    
    // Ingredient context
    if (includedIngredients != null && includedIngredients.isNotEmpty) {
      prompt.write('Known ingredients: ${includedIngredients.join(', ')}. ');
    }
    if (excludedIngredients != null && excludedIngredients.isNotEmpty) {
      prompt.write('Exclude these ingredients: ${excludedIngredients.join(', ')}. ');
    }
    
    // Weight context
    if (estimatedWeight != null && estimatedWeight > 0) {
      prompt.write('Estimated weight: ${estimatedWeight}g. ');
    }
    
    // Diet-specific instructions
    if (dietType == 'Keto') {
      prompt.write('This is for a ketogenic diet - focus on net carbs (total carbs minus fiber), ');
      prompt.write('prioritize fat content accuracy, and watch for hidden sugars. ');
    } else if (dietType == 'Carnivore') {
      prompt.write('This is for a carnivore diet - focus only on animal-based foods, ');
      prompt.write('eliminate any plant-based estimates unless specifically visible. ');
    } else if (isLowFat) {
      prompt.write('This is for a low-fat diet (under 10% fat content). ');
      prompt.write('Pay special attention to cooking methods that might add fat. ');
    }
    
    // JSON structure requirement
    prompt.write('Provide a detailed JSON object with these exact fields: ');
    prompt.write('{"food": "name", "kcal": calories_for_entire_portion, ');
    prompt.write('"protein_g": protein_grams, "fat_g": fat_grams, "carbs_g": carb_grams, ');
    prompt.write('"fiber_g": fiber_grams, "estimated_weight_g": total_weight_grams, ');
    prompt.write('"confidence_score": 0.0_to_1.0, "requires_follow_up": boolean, ');
    prompt.write('"follow_up_questions": ["question1", "question2"], ');
    prompt.write('"detected_ingredients": ["ingredient1", "ingredient2"], ');
    prompt.write('"cooking_method": "method", ');
    prompt.write('"nutrition_confidence": {"protein": 0.0_to_1.0, "fat": 0.0_to_1.0, "carbs": 0.0_to_1.0}}. ');
    
    // Analysis focus
    prompt.write('Focus on the ENTIRE portion shown, not per-100g values. ');
    prompt.write('Provide confidence scores based on image clarity, angle, and visible details. ');
    prompt.write('If confidence is low (<0.8), set requires_follow_up to true and suggest specific follow-up questions. ');
    prompt.write('Return ONLY the JSON without markdown formatting or explanations.');
    
    return prompt.toString();
  }
  
  // Progressive analysis with follow-up
  Future<FoodAnalysisResult?> progressiveAnalysis({
    required List<File> imageFiles,
    String? dishName,
    bool isLowFat = false,
    String dietType = 'Standard',
    List<String>? includedIngredients,
    List<String>? excludedIngredients,
    String? cookingMethod,
    String? voiceNotes,
    String? preparationNotes,
    double? estimatedWeight,
  }) async {
    FoodAnalysisResult? bestResult;
    List<String> imageUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final result = await analyzeFoodImage(
          imageFiles[i],
          dishName: dishName,
          isLowFat: isLowFat,
          dietType: dietType,
          shouldUploadImage: true, // Ensure images are uploaded during progressive analysis
          includedIngredients: includedIngredients,
          excludedIngredients: excludedIngredients,
          cookingMethod: cookingMethod,
          voiceNotes: voiceNotes,
          preparationNotes: preparationNotes,
          estimatedWeight: estimatedWeight,
          analysisAttempt: i + 1,
          previousImageUrls: imageUrls,
        );
        
        if (result != null) {
          if (result.imageUrl != null) {
            imageUrls.add(result.imageUrl!);
          }
          
          // Keep the result with highest confidence
          if (bestResult == null || result.confidenceScore > bestResult.confidenceScore) {
            bestResult = result.copyWith(imageUrls: imageUrls);
          }
        }
      } catch (e) {
        debugPrint('Error in progressive analysis step ${i + 1}: $e');
      }
    }
    
    return bestResult;
  }
  
  // Generate follow-up questions based on analysis
  List<String> generateFollowUpQuestions(FoodAnalysisResult result) {
    List<String> questions = [];
    
    if (result.confidenceScore < 0.7) {
      questions.add("Could you provide a clearer photo from directly above?");
      questions.add("Can you include your hand or a common object for size reference?");
    }
    
    if (result.getNutrientConfidence('fat') < 0.8) {
      questions.add("What cooking method was used? Any oils or butter added?");
    }
    
    if (result.detectedIngredients.length < 2) {
      questions.add("Are there any sauces, dressings, or seasonings not visible in the image?");
    }
    
    if (result.estimatedWeight == 0) {
      questions.add("How does this portion compare to your typical serving size?");
    }
    
    return questions;
  }
  
  // Enhance analysis with Open Food Facts data
  Future<FoodAnalysisResult> enhanceWithOpenFoodFacts(FoodAnalysisResult result) async {
    try {
      // Search for similar products in Open Food Facts
      final products = await _openFoodFactsService.searchProducts(result.foodName, limit: 3);
      
      if (products.isNotEmpty) {
        final bestMatch = products.first;
        
        // Extract additional ingredients from Open Food Facts
        final enhancedIngredients = List<String>.from(result.detectedIngredients);
        
        // Add unique ingredients from Open Food Facts
        for (var ingredient in bestMatch.ingredients) {
          if (!enhancedIngredients.any((existing) => 
              existing.toLowerCase().contains(ingredient.toLowerCase()) ||
              ingredient.toLowerCase().contains(existing.toLowerCase()))) {
            enhancedIngredients.add(ingredient);
          }
        }
        
        // Calculate improved confidence if we found a good match
        double improvedConfidence = result.confidenceScore;
        if (bestMatch.name.toLowerCase().contains(result.foodName.toLowerCase()) ||
            result.foodName.toLowerCase().contains(bestMatch.name.toLowerCase())) {
          improvedConfidence = (result.confidenceScore + 0.2).clamp(0.0, 1.0);
        }
        
        // Enhanced nutrition confidence based on Open Food Facts data
        final enhancedNutritionConfidence = Map<String, double>.from(result.nutritionConfidence);
        if (bestMatch.energyKcal100g != null) {
          enhancedNutritionConfidence['calories'] = (enhancedNutritionConfidence['calories'] ?? 0.7) + 0.1;
        }
        if (bestMatch.proteins100g != null) {
          enhancedNutritionConfidence['protein'] = (enhancedNutritionConfidence['protein'] ?? 0.7) + 0.1;
        }
        if (bestMatch.carbohydrates100g != null) {
          enhancedNutritionConfidence['carbs'] = (enhancedNutritionConfidence['carbs'] ?? 0.7) + 0.1;
            }
        if (bestMatch.fat100g != null) {
          enhancedNutritionConfidence['fat'] = (enhancedNutritionConfidence['fat'] ?? 0.7) + 0.1;
          }
        
        return result.copyWith(
          detectedIngredients: enhancedIngredients,
          confidenceScore: improvedConfidence,
          nutritionConfidence: enhancedNutritionConfidence,
          requiresFollowUp: improvedConfidence < 0.8,
        );
      }
      
      return result;
    } catch (e) {
      debugPrint('Error enhancing with Open Food Facts: $e');
      return result;
    }
  }
  
  // Get nutrition validation from Open Food Facts
  Future<Map<String, dynamic>?> validateNutritionWithOpenFoodFacts(String foodName) async {
    try {
      final nutritionData = await _openFoodFactsService.getNutritionData(foodName);
      return nutritionData;
    } catch (e) {
      debugPrint('Error validating nutrition with Open Food Facts: $e');
      return null;
    }
  }
} 