import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class OpenFoodFactsProduct {
  final String id;
  final String name;
  final String? brand;
  final List<String> ingredients;
  final String? imageUrl;
  final Map<String, dynamic>? nutrition;
  final List<String> categories;
  final String? servingSize;
  final double? energyKcal100g;
  final double? proteins100g;
  final double? carbohydrates100g;
  final double? fat100g;
  final double? fiber100g;

  OpenFoodFactsProduct({
    required this.id,
    required this.name,
    this.brand,
    this.ingredients = const [],
    this.imageUrl,
    this.nutrition,
    this.categories = const [],
    this.servingSize,
    this.energyKcal100g,
    this.proteins100g,
    this.carbohydrates100g,
    this.fat100g,
    this.fiber100g,
  });

  factory OpenFoodFactsProduct.fromJson(Map<String, dynamic> json) {
    final product = json['product'] ?? json;
    
    // Parse ingredients
    final ingredientsList = <String>[];
    if (product['ingredients'] != null) {
      for (var ingredient in product['ingredients']) {
        final text = ingredient['text'] ?? ingredient['id'] ?? '';
        if (text.isNotEmpty) {
          ingredientsList.add(text);
        }
      }
    }
    
    // Parse categories
    final categoriesList = <String>[];
    if (product['categories'] != null) {
      categoriesList.addAll(product['categories'].toString().split(',').map((c) => c.trim()));
    }
    
    // Parse nutrition data
    final nutriments = product['nutriments'] ?? {};
    
    return OpenFoodFactsProduct(
      id: product['id'] ?? product['code'] ?? '',
      name: product['product_name'] ?? product['product_name_en'] ?? 'Unknown Product',
      brand: product['brands'],
      ingredients: ingredientsList,
      imageUrl: product['image_url'] ?? product['image_front_url'],
      nutrition: nutriments,
      categories: categoriesList,
      servingSize: product['serving_size'],
      energyKcal100g: _parseDouble(nutriments['energy-kcal_100g']),
      proteins100g: _parseDouble(nutriments['proteins_100g']),
      carbohydrates100g: _parseDouble(nutriments['carbohydrates_100g']),
      fat100g: _parseDouble(nutriments['fat_100g']),
      fiber100g: _parseDouble(nutriments['fiber_100g']),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'ingredients': ingredients,
      'imageUrl': imageUrl,
      'nutrition': nutrition,
      'categories': categories,
      'servingSize': servingSize,
      'energyKcal100g': energyKcal100g,
      'proteins100g': proteins100g,
      'carbohydrates100g': carbohydrates100g,
      'fat100g': fat100g,
      'fiber100g': fiber100g,
    };
  }
}

class OpenFoodFactsService {
  static final OpenFoodFactsService _instance = OpenFoodFactsService._internal();
  factory OpenFoodFactsService() => _instance;
  
  OpenFoodFactsService._internal();
  
  static const String _baseUrl = 'https://world.openfoodfacts.org';
  
  // Search for products by name or ingredients
  Future<List<OpenFoodFactsProduct>> searchProducts(String query, {int limit = 20}) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = '$_baseUrl/cgi/search.pl?search_terms=$encodedQuery&search_simple=1&action=process&json=1&page_size=$limit';
      
      debugPrint('Searching Open Food Facts: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'FOCUZ-App/1.0 (contact@focuzapp.com)',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = <OpenFoodFactsProduct>[];
        
        if (data['products'] != null) {
          for (var productData in data['products']) {
            try {
              final product = OpenFoodFactsProduct.fromJson(productData);
              if (product.name.isNotEmpty) {
                products.add(product);
              }
            } catch (e) {
              debugPrint('Error parsing product: $e');
            }
          }
        }
        
        debugPrint('Found ${products.length} products');
        return products;
      } else {
        throw Exception('Failed to search products: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error searching Open Food Facts: $e');
      return [];
    }
  }
  
  // Get product by barcode
  Future<OpenFoodFactsProduct?> getProductByBarcode(String barcode) async {
    try {
      final url = '$_baseUrl/api/v0/product/$barcode.json';
      
      debugPrint('Getting product by barcode: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'FOCUZ-App/1.0 (contact@focuzapp.com)',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 1 && data['product'] != null) {
          return OpenFoodFactsProduct.fromJson(data);
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting product by barcode: $e');
      return null;
    }
  }
  
  // Search for ingredients specifically
  Future<List<String>> searchIngredients(String query, {int limit = 20}) async {
    try {
      final products = await searchProducts(query, limit: limit);
      final ingredients = <String>{};
      
      for (var product in products) {
        for (var ingredient in product.ingredients) {
          if (ingredient.toLowerCase().contains(query.toLowerCase())) {
            ingredients.add(ingredient);
          }
        }
      }
      
      return ingredients.take(limit).toList();
    } catch (e) {
      debugPrint('Error searching ingredients: $e');
      return [];
    }
  }
  
  // Get common ingredients for a food category
  Future<List<String>> getCommonIngredients(String category) async {
    try {
      final encodedCategory = Uri.encodeComponent(category);
      final url = '$_baseUrl/category/$encodedCategory.json?page_size=50';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'FOCUZ-App/1.0 (contact@focuzapp.com)',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ingredients = <String>{};
        
        if (data['products'] != null) {
          for (var productData in data['products']) {
            try {
              final product = OpenFoodFactsProduct.fromJson(productData);
              ingredients.addAll(product.ingredients);
            } catch (e) {
              debugPrint('Error parsing product for ingredients: $e');
            }
          }
        }
        
        // Return most common ingredients (could implement frequency counting)
        return ingredients.take(20).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Error getting common ingredients: $e');
      return [];
    }
  }
  
  // Get nutrition data for an ingredient/product
  Future<Map<String, double>?> getNutritionData(String productName) async {
    try {
      final products = await searchProducts(productName, limit: 1);
      
      if (products.isNotEmpty) {
        final product = products.first;
        return {
          'calories': product.energyKcal100g ?? 0,
          'protein': product.proteins100g ?? 0,
          'carbs': product.carbohydrates100g ?? 0,
          'fat': product.fat100g ?? 0,
          'fiber': product.fiber100g ?? 0,
        };
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting nutrition data: $e');
      return null;
    }
  }
  
  // Suggest similar products based on ingredients
  Future<List<OpenFoodFactsProduct>> getSimilarProducts(List<String> ingredients, {int limit = 10}) async {
    try {
      final query = ingredients.take(3).join(' '); // Use first 3 ingredients
      return await searchProducts(query, limit: limit);
    } catch (e) {
      debugPrint('Error getting similar products: $e');
      return [];
    }
  }
} 