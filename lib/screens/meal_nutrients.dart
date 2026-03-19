import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for Ovarrior Nutrient Calculator API
class NutrientApiService {
  static const String baseUrl = 'https://ovarrior-nutrient-api.onrender.com';
  
  /// Search for foods in the USDA database
  /// Returns list of matching foods
  static Future<List<FoodSearchResult>> searchFoods(String query) async {
    if (query.length < 2) return [];
    
    try {
      final url = Uri.parse('$baseUrl/search-foods?q=${Uri.encodeComponent(query)}');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final results = data['results'] as List;
          return results.map((r) => FoodSearchResult.fromJson(r)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error searching foods: $e');
      return [];
    }
  }
  
  /// Calculate nutrients for a list of foods
  static Future<NutrientCalculation?> calculateNutrients(List<MealFood> foods) async {
    try {
      final url = Uri.parse('$baseUrl/calculate-nutrients');
      final body = jsonEncode({
        'foods': foods.map((f) => {
          'food_name': f.foodName,
          'grams': f.grams,
        }).toList(),
      });
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return NutrientCalculation.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      print('Error calculating nutrients: $e');
      return null;
    }
  }
}

/// Food search result from API
class FoodSearchResult {
  final String fdcId;
  final String foodName;
  final int categoryId;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double fiberPer100g;
  
  FoodSearchResult({
    required this.fdcId,
    required this.foodName,
    required this.categoryId,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.fiberPer100g,
  });
  
  factory FoodSearchResult.fromJson(Map<String, dynamic> json) {
    return FoodSearchResult(
      fdcId: json['fdc_id'].toString(),
      foodName: json['food_name'],
      categoryId: json['category_id'],
      caloriesPer100g: (json['calories_per_100g'] as num).toDouble(),
      proteinPer100g: (json['protein_per_100g'] as num).toDouble(),
      carbsPer100g: (json['carbs_per_100g'] as num).toDouble(),
      fatPer100g: (json['fat_per_100g'] as num).toDouble(),
      fiberPer100g: (json['fiber_per_100g'] as num).toDouble(),
    );
  }
}

/// Food item for meal calculation
class MealFood {
  final String foodName;
  final double grams;
  
  MealFood({required this.foodName, required this.grams});
}

/// Nutrient calculation result
class NutrientCalculation {
  final NutrientTotals totals;
  final List<FoodBreakdown> foods;
  final List<String> notFound;
  
  NutrientCalculation({
    required this.totals,
    required this.foods,
    required this.notFound,
  });
  
  factory NutrientCalculation.fromJson(Map<String, dynamic> json) {
    return NutrientCalculation(
      totals: NutrientTotals.fromJson(json['totals']),
      foods: (json['foods'] as List)
          .map((f) => FoodBreakdown.fromJson(f))
          .toList(),
      notFound: List<String>.from(json['not_found'] ?? []),
    );
  }
}

class NutrientTotals {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  
  NutrientTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });
  
  factory NutrientTotals.fromJson(Map<String, dynamic> json) {
    return NutrientTotals(
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      fiber: (json['fiber'] as num).toDouble(),
    );
  }
}

class FoodBreakdown {
  final String foodName;
  final double grams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  
  FoodBreakdown({
    required this.foodName,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });
  
  factory FoodBreakdown.fromJson(Map<String, dynamic> json) {
    return FoodBreakdown(
      foodName: json['food_name'],
      grams: (json['grams'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      fiber: (json['fiber'] as num).toDouble(),
    );
  }
}