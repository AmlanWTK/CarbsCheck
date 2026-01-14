import 'package:flutter/services.dart';
import 'dart:convert';

/// 🎯 Local Food Database Service
/// Loads USDA foundation foods from JSON file
/// Provides instant search without network calls
class LocalFoodDatabaseService {
  static final LocalFoodDatabaseService _instance = LocalFoodDatabaseService._internal();
  
  factory LocalFoodDatabaseService() {
    return _instance;
  }
  
  LocalFoodDatabaseService._internal();
  
  List<FoodItem> _foodDatabase = [];
  bool _isLoaded = false;

  /// ⚡ Load food database from JSON asset on app startup
  /// Call this in your main() or initState()
 Future<void> loadDatabase() async {
  if (_isLoaded) {
    print('📦 Food database already loaded');
    return;
  }

  try {
    print('📥 Loading USDA foundation foods from JSON...');

    // Load JSON file from assets
    final jsonString = await rootBundle.loadString(
      'assets/FoodData_Central_foundation_food_json_2025-12-18.json',
    );

    // Decode the JSON
    final data = jsonDecode(jsonString);

    // ✅ Fix: Use the correct root key used in USDA JSON
    // Older code: data['FoundationFoods'] → could be wrong
    final foodsList = data['FoundationFoods'] as List? ??
        data['foods'] as List? ?? // fallback for different JSONs
        [];

    print('📦 Parsing ${foodsList.length} foods...');

    _foodDatabase = foodsList
        .map((food) {
          try {
            return FoodItem.fromJSON(food);
          } catch (e) {
            print('⚠️ Error parsing food: $e');
            return null;
          }
        })
        .whereType<FoodItem>()
        .toList();

    _isLoaded = true;
    print('✅ Loaded ${_foodDatabase.length} foods successfully');
  } catch (e) {
    print('❌ Error loading food database: $e');
    throw Exception('Failed to load food database: $e');
  }
}


  /// 🔍 Search foods locally (instant results)
  /// Supports partial matching, fuzzy search, multiple keywords
  List<FoodItem> searchFoods(String query) {
    if (!_isLoaded) {
      print('⚠️ Database not loaded yet');
      return [];
    }

    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();
    final queryTokens = queryLower.split(' ').where((t) => t.isNotEmpty).toList();

    // Score each food based on match quality
    List<MapEntry<FoodItem, int>> scoredFoods = [];

    for (var food in _foodDatabase) {
      final foodNameLower = food.description.toLowerCase();
      int score = 0;

      for (var token in queryTokens) {
        if (foodNameLower.startsWith(token)) {
          score += 100; // Highest: starts with token
        } else if (foodNameLower.contains(token)) {
          score += 50; // Medium: contains token
        } else if (_fuzzyMatch(token, foodNameLower)) {
          score += 20; // Low: fuzzy match
        }
      }

      if (score > 0) {
        scoredFoods.add(MapEntry(food, score));
      }
    }

    // Sort by score (highest first), then by name
    scoredFoods.sort((a, b) {
      if (a.value != b.value) {
        return b.value.compareTo(a.value);
      }
      return a.key.description.compareTo(b.key.description);
    });

    // Return top 10 results
    return scoredFoods.take(10).map((e) => e.key).toList();
  }

  /// Get a specific food by description
  FoodItem? getFoodByDescription(String description) {
    try {
      return _foodDatabase.firstWhere(
        (food) => food.description.toLowerCase() == description.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all foods (for browsing)
  List<FoodItem> getAllFoods() {
    return _foodDatabase;
  }

  /// Get foods by category
  List<FoodItem> getFoodsByCategory(String categoryKeyword) {
    final keyword = categoryKeyword.toLowerCase();
    return _foodDatabase
        .where((food) => food.description.toLowerCase().contains(keyword))
        .toList();
  }

  /// Get database stats
  int getTotalFoodCount() => _foodDatabase.length;
  
  bool get isLoaded => _isLoaded;

  /// 🔤 Simple fuzzy matching (Levenshtein-lite)
  bool _fuzzyMatch(String query, String text) {
    if (query.isEmpty) return true;
    if (text.isEmpty) return false;

    int matchCount = 0;
    int queryIdx = 0;

    for (int i = 0; i < text.length && queryIdx < query.length; i++) {
      if (text[i] == query[queryIdx]) {
        matchCount++;
        queryIdx++;
      }
    }

    return matchCount >= (query.length * 0.6); // 60% match threshold
  }
}

/// 🥗 Model for a single food item from USDA database
class FoodItem {
  final String fdcId;
  final String description;
  final String foodCategory;
  final double servingSizeGrams;
  final String servingSizeUnit;
  
  // Nutrients per serving (100g baseline from USDA)
  final double carbohydrates;
  final double protein;
  final double fat;
  final double energy; // kcal

  FoodItem({
    required this.fdcId,
    required this.description,
    required this.foodCategory,
    required this.servingSizeGrams,
    required this.servingSizeUnit,
    required this.carbohydrates,
    required this.protein,
    required this.fat,
    required this.energy,
  });

  /// Parse from USDA JSON format
 factory FoodItem.fromJSON(Map<String, dynamic> json) {
  double servingGrams = 100.0;
  String servingUnit = 'g';

  final portionData = json['servingSize'] as Map<String, dynamic>? ?? json['servingSizeData'] as Map<String, dynamic>?;
  if (portionData != null) {
    servingGrams = (portionData['value'] as num?)?.toDouble() ?? 100.0;
    servingUnit = portionData['measureUnit']?['abbreviation']?.toString() ?? 'g';
  }

  final foodNutrients = json['foodNutrients'] as List? ?? [];

  double carbs = 0;
  double protein = 0;
  double fat = 0;
  double energy = 0;

  for (var nutrient in foodNutrients) {
    final nutrientData = nutrient['nutrient'] as Map<String, dynamic>?;

    final nutrientId = nutrientData?['id'] as int?;
    final nutrientNumber = nutrientData?['number']?.toString() ?? nutrientData?['nutrientNumber']?.toString();
    final value = (nutrient['amount'] as num?)?.toDouble() ?? (nutrient['value'] as num?)?.toDouble() ?? 0.0;

    switch (nutrientNumber) {
      case '205': // Carbs
      case '1005':
        carbs = value;
        break;
      case '203': // Protein
      case '1003':
        protein = value;
        break;
      case '204': // Fat
      case '1004':
        fat = value;
        break;
      case '208': // Energy kcal
      case '1008':
        energy = value;
        break;
    }
  }

  return FoodItem(
    fdcId: json['fdcId']?.toString() ?? '',
    description: json['description']?.toString() ?? 'Unknown',
    foodCategory: json['foodCategory']?['description']?.toString() ?? '',
    servingSizeGrams: servingGrams,
    servingSizeUnit: servingUnit,
    carbohydrates: carbs,
    protein: protein,
    fat: fat,
    energy: energy,
  );
}


  /// Scale nutrients to custom serving size
  Map<String, double> getNutrients(double grams) {
    final scale = grams / 100.0;
    return {
      'carbs': carbohydrates * scale,
      'protein': protein * scale,
      'fat': fat * scale,
      'calories': energy * scale,
    };
  }

  @override
  String toString() => '$description ($servingSizeGrams${servingSizeUnit})';
}
