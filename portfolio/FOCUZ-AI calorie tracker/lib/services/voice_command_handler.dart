import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/water_can/water_can_provider.dart';
import '../features/sleep/sleep_provider.dart';
import '../features/weight/weight_provider.dart';
import '../features/training/training_provider.dart';
import '../features/meals/meal_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VoiceCommandHandler {
  static final VoiceCommandHandler _instance = VoiceCommandHandler._internal();
  factory VoiceCommandHandler() => _instance;
  
  VoiceCommandHandler._internal();
  
  // OpenAI API key removed for security
  final String _apiKey = 'REMOVED_FOR_SECURITY';
  
  // Process voice transcription using OpenAI
  Future<Map<String, dynamic>> processVoiceCommand(String transcription) async {
    debugPrint('Processing voice command: $transcription');
    
    try {
      // Prepare OpenAI request payload
      final payload = {
        'model': 'gpt-4o',
        'messages': [
          {
            'role': 'system',
            'content': '''
You are a health tracking app assistant that processes voice commands.
Extract the intent and entities from the user's command.
Respond ONLY with a JSON object with the following structure:
{
  "intent": "log_water|log_weight|log_sleep|log_training|log_meal",
  "entities": {
    "amount": number,  // for water in ml
    "unit": string,    // for units like "l", "ml", "oz"
    "beverage": string, // for type of drink
    "weight": number,  // for weight in kg
    "duration": number, // for duration in hours or minutes
    "quality": number, // for sleep quality (1-5)
    "type": string,    // for training type
    "meal_name": string, // for meal name
    "calories": number  // for calories
  },
  "display_message": "A user-friendly confirmation message"
}

Only provide entities that are relevant to the intent. Don't output text outside the JSON.
'''
          },
          {
            'role': 'user',
            'content': transcription
          }
        ],
        'max_tokens': 500
      };
      
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final content = responseData['choices'][0]['message']['content'];
        
        // Extract JSON from response
        try {
          final jsonData = jsonDecode(content);
          return jsonData;
        } catch (e) {
          // If direct parsing fails, try to extract JSON from text
          final jsonMatch = RegExp(r'{.*}', dotAll: true).firstMatch(content);
          if (jsonMatch != null) {
            final jsonStr = jsonMatch.group(0);
            return jsonDecode(jsonStr!);
          }
          throw Exception('Failed to parse JSON response');
        }
      } else {
        throw Exception('OpenAI request failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error processing voice command: $e');
      return {
        'intent': 'unknown',
        'entities': {},
        'display_message': 'Sorry, I couldn\'t understand that command.'
      };
    }
  }
  
  // Handle a voice command by intent
  Future<String> handleCommand(Map<String, dynamic> commandData, BuildContext context) async {
    final intent = commandData['intent'] as String;
    final entities = commandData['entities'] as Map<String, dynamic>?;
    final displayMessage = commandData['display_message'] as String? ?? 'Processing command...';
    
    debugPrint('Handling command: $intent with entities: $entities');
    
    try {
      switch (intent) {
        case 'log_water':
          await _handleLogWater(entities, context);
          break;
        case 'log_weight':
          await _handleLogWeight(entities, context);
          break;
        case 'log_sleep':
          await _handleLogSleep(entities, context);
          break;
        case 'log_training':
          await _handleLogTraining(entities, context);
          break;
        case 'log_meal':
          await _handleLogMeal(entities, context);
          break;
        default:
          return 'Unknown command: $intent';
      }
      
      return displayMessage;
    } catch (e) {
      debugPrint('Error executing command: $e');
      return 'Error: $e';
    }
  }
  
  // Handle water logging command
  Future<void> _handleLogWater(Map<String, dynamic>? entities, BuildContext context) async {
    if (entities == null) return;
    
    try {
      final waterProvider = WaterCanProvider.of(context);
      
      // Extract amount from entities
      final amount = _extractNumberEntity(entities, 'amount');
      if (amount != null) {
        // Convert to milliliters if needed
        int mlAmount = amount;
        
        // Check if unit is specified
        final unit = _extractStringEntity(entities, 'unit')?.toLowerCase();
        if (unit != null) {
          if (unit == 'l' || unit == 'liter' || unit == 'liters') {
            mlAmount = amount * 1000;
          } else if (unit == 'oz' || unit == 'ounce' || unit == 'ounces') {
            mlAmount = (amount * 29.574).round();
          }
        }
        
        // Check for beverage type
        final beverage = _extractStringEntity(entities, 'beverage');
        if (beverage?.toLowerCase() == 'water') {
          await waterProvider.addWater(mlAmount);
        } else if (beverage != null) {
          await waterProvider.addBeverage(beverage, mlAmount);
        } else {
          // Default to water
          await waterProvider.addWater(mlAmount);
        }
        
        debugPrint('Logged $mlAmount ml of ${beverage ?? 'water'}');
      }
    } catch (e) {
      debugPrint('Error handling log_water command: $e');
      rethrow;
    }
  }
  
  // Handle weight logging command
  Future<void> _handleLogWeight(Map<String, dynamic>? entities, BuildContext context) async {
    if (entities == null) return;
    
    try {
      final weightProvider = WeightProvider.of(context);
      
      // Extract weight value from entities
      final weight = _extractNumberEntity(entities, 'weight');
      if (weight != null) {
        // Convert to kilograms if needed
        double kgWeight = weight.toDouble();
        
        // Check if unit is specified
        final unit = _extractStringEntity(entities, 'unit')?.toLowerCase();
        if (unit != null) {
          if (unit == 'lb' || unit == 'lbs' || unit == 'pound' || unit == 'pounds') {
            kgWeight = weight * 0.45359237;
          }
        }
        
        await weightProvider.logWeight(kgWeight);
        debugPrint('Logged weight: $kgWeight kg');
      }
    } catch (e) {
      debugPrint('Error handling log_weight command: $e');
      rethrow;
    }
  }
  
  // Handle sleep logging command
  Future<void> _handleLogSleep(Map<String, dynamic>? entities, BuildContext context) async {
    if (entities == null) return;
    
    try {
      final sleepProvider = SleepProvider.of(context);
      
      // Extract duration from entities
      final duration = _extractNumberEntity(entities, 'duration');
      if (duration != null) {
        // Extract sleep quality if available
        final quality = _extractNumberEntity(entities, 'quality') ?? 3;
        
        await sleepProvider.logSleep(duration.toDouble(), quality.toInt());
        debugPrint('Logged sleep: $duration hours with quality $quality');
      }
    } catch (e) {
      debugPrint('Error handling log_sleep command: $e');
      rethrow;
    }
  }
  
  // Handle training logging command
  Future<void> _handleLogTraining(Map<String, dynamic>? entities, BuildContext context) async {
    if (entities == null) return;
    
    try {
      final trainingProvider = TrainingProvider.of(context);
      
      // Extract training type and duration
      final type = _extractStringEntity(entities, 'type');
      final duration = _extractNumberEntity(entities, 'duration');
      
      if (type != null && duration != null) {
        await trainingProvider.logTraining(type, duration.toInt());
        debugPrint('Logged training: $type for $duration minutes');
      }
    } catch (e) {
      debugPrint('Error handling log_training command: $e');
      rethrow;
    }
  }
  
  // Handle meal logging command
  Future<void> _handleLogMeal(Map<String, dynamic>? entities, BuildContext context) async {
    if (entities == null) return;
    
    try {
      // Use Provider.of instead of MealProvider.of
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      
      // Extract meal name and calories
      final name = _extractStringEntity(entities, 'meal_name');
      final calories = _extractNumberEntity(entities, 'calories');
      
      if (name != null && calories != null) {
        await mealProvider.logMeal(name, calories.toInt());
        debugPrint('Logged meal: $name with $calories calories');
      }
    } catch (e) {
      debugPrint('Error handling log_meal command: $e');
      rethrow;
    }
  }
  
  // Helper method to extract number from entities
  int? _extractNumberEntity(Map<String, dynamic>? entities, String entityName) {
    if (entities == null || !entities.containsKey(entityName)) return null;
    
    try {
      final entity = entities[entityName];
      if (entity is int) {
        return entity;
      } else if (entity is double) {
        return entity.round();
      } else if (entity is String) {
        return int.tryParse(entity);
      } else if (entity is List && entity.isNotEmpty) {
        if (entity[0] is Map && entity[0].containsKey('value')) {
          return int.tryParse(entity[0]['value'].toString());
        }
        return int.tryParse(entity[0].toString());
      } else if (entity is Map && entity.containsKey('value')) {
        return int.tryParse(entity['value'].toString());
      }
    } catch (e) {
      debugPrint('Error extracting number entity $entityName: $e');
    }
    
    return null;
  }
  
  // Helper method to extract string from entities
  String? _extractStringEntity(Map<String, dynamic>? entities, String entityName) {
    if (entities == null || !entities.containsKey(entityName)) return null;
    
    try {
      final entity = entities[entityName];
      if (entity is String) {
        return entity;
      } else if (entity is List && entity.isNotEmpty) {
        if (entity[0] is Map && entity[0].containsKey('value')) {
          return entity[0]['value'].toString();
        }
        return entity[0].toString();
      } else if (entity is Map && entity.containsKey('value')) {
        return entity['value'].toString();
      }
    } catch (e) {
      debugPrint('Error extracting string entity $entityName: $e');
    }
    
    return null;
  }
} 