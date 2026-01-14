import 'package:http/http.dart' as http;
import 'dart:convert';


class USDAServingSize {
  /// Unique identifier for this serving size
  final String servingSizeUnitId;

  /// Standard serving size amount (e.g., 1)
  final double amount;

  /// Unit of measurement (e.g., "cup", "g", "oz")
  final String unitName;

  final double weightGrams;

  /// Human-readable description
  /// Example: "1 cup cooked"
  final String description;

  /// Constructor
  USDAServingSize({
    required this.servingSizeUnitId,
    required this.amount,
    required this.unitName,
    required this.weightGrams,
    required this.description,
  });

  /// Create from USDA API JSON response
  factory USDAServingSize.fromJson(Map<String, dynamic> json) {
    return USDAServingSize(
      servingSizeUnitId: json['servingSizeUnitId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 1.0,
      unitName: json['unitName'] as String? ?? 'unit',
      weightGrams: (json['weightGrams'] as num?)?.toDouble() ?? 100.0,
      description: _buildDescription(
        json['amount'] as num?,
        json['unitName'] as String?,
      ),
    );
  }

  /// Build human-readable description from amount and unit
  static String _buildDescription(num? amount, String? unit) {
    if (amount == null || unit == null) return 'Standard serving';
    
    final amountStr = amount is int ? amount.toString() : 
                      (amount as double).toStringAsFixed(1);
    return '$amountStr $unit';
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'servingSizeUnitId': servingSizeUnitId,
    'amount': amount,
    'unitName': unitName,
    'weightGrams': weightGrams,
    'description': description,
  };

  @override
  String toString() => 'USDAServingSize('
      'amount: $amount, '
      'unit: $unitName, '
      'grams: $weightGrams)';
}

/// Represents a food search result from USDA API
/// 
/// Contains basic info about a food including its FDC ID
/// and available serving sizes
class USDAFoodSearchResult {
  /// USDA FoodData Central ID
  /// Unique identifier for this food
  /// Used to fetch detailed nutrition later
  /// Example: "169897" for rice, white, cooked
  final String fdcId;

  /// Display name of the food
  /// Example: "Rice, white, cooked"
  final String description;

  /// Food category (USDA data type)
  /// "SR Legacy", "Survey (FNDDS)", "Foundation", "Branded"
  final String dataType;

  /// List of serving sizes available for this food
  /// Example: [1 cup, 100g, 1 tbsp, etc.]
  final List<USDAServingSize> servingSizes;

  /// Primary/most common serving size for this food
  /// Usually what users will select by default
  final USDAServingSize? primaryServingSize;

  /// Constructor
  USDAFoodSearchResult({
    required this.fdcId,
    required this.description,
    required this.dataType,
    required this.servingSizes,
    this.primaryServingSize,
  });

  /// Create from USDA API JSON response
  factory USDAFoodSearchResult.fromJson(Map<String, dynamic> json) {
    final servingSizesList = (json['foodPortions'] as List<dynamic>?)
        ?.map((p) => USDAServingSize.fromJson(p as Map<String, dynamic>))
        .toList() ?? [];

    return USDAFoodSearchResult(
      fdcId: json['fdcId']?.toString() ?? '',
      description: json['description'] as String? ?? 'Unknown',
      dataType: json['dataType'] as String? ?? 'Unknown',
      servingSizes: servingSizesList,
      primaryServingSize: servingSizesList.isNotEmpty ? 
          servingSizesList.first : null,
    );
  }

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() => {
    'fdcId': fdcId,
    'description': description,
    'dataType': dataType,
    'servingSizes': servingSizes.map((s) => s.toJson()).toList(),
    'primaryServingSize': primaryServingSize?.toJson(),
  };

  /// Get standard serving size in grams
  /// 
  /// Returns the grams of the primary serving size
  /// Useful for storing in food_serving_standards.dart
  /// 
  /// Example: Rice → 158g (1 cup cooked)
  double getStandardServingGrams() {
    return primaryServingSize?.weightGrams ?? 100.0;
  }

  /// Get serving description for display
  /// 
  /// Example: "1 cup cooked"
  String getServingDescription() {
    return primaryServingSize?.description ?? 'Standard serving';
  }

  /// Check if this food has valid serving sizes
  bool hasValidServingSizes() => servingSizes.isNotEmpty;

  @override
  String toString() => 'USDAFoodSearchResult('
      'fdcId: $fdcId, '
      'description: $description, '
      'servings: ${servingSizes.length})';
}

class USDAService {
  /// USDA API base URL
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';



  final String apiKey;


  final http.Client _httpClient;

  final Map<String, List<USDAFoodSearchResult>> _searchCache = {};


  final Map<String, Map<String, dynamic>> _detailCache = {};

  /// Constructor
  USDAService({
    required this.apiKey,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  
Future<List<USDAFoodSearchResult>> searchFood(
  String query, {
  int limit = 5,
  int pageSize = 20,
}) async {
  if (_searchCache.containsKey(query)) {
    return _searchCache[query]!;
  }

  final url = Uri.parse(
    '$_baseUrl/foods/search?api_key=$apiKey',
  );

  final body = {
    "generalSearchInput": query,
    "pageSize": pageSize,
    "requireAllWords": false,
  };

  final response = await _httpClient.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  if (response.statusCode != 200) {
    throw Exception('USDA API error: ${response.body}');
  }

  final data = jsonDecode(response.body);
  final foods = (data['foods'] as List<dynamic>)
      .take(limit)
      .map((f) => USDAFoodSearchResult.fromJson(f))
      .toList();

  _searchCache[query] = foods;
  return foods;
}


  
  Future<Map<String, dynamic>> getFoodDetails(String fdcId) async {
    // Check cache first
    if (_detailCache.containsKey(fdcId)) {
      print('📦 Cache hit for FDC ID: $fdcId');
      return _detailCache[fdcId]!;
    }

    try {
      print('🔍 Fetching details for FDC ID: $fdcId');

      final url = Uri.parse(
        '$_baseUrl/$fdcId'
        '?api_key=$apiKey',
      );

      final response = await _httpClient.get(url);

      if (response.statusCode != 200) {
        throw Exception(
          'USDA API Error: ${response.statusCode} - ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Cache the result
      _detailCache[fdcId] = data;

      print('✅ Retrieved details for FDC ID: $fdcId');
      return data;
    } catch (e) {
      print('❌ Detail fetch error: $e');
      rethrow;
    }
  }

  
 Map<String, double> extractNutrients(
  Map<String, dynamic> foodData,
  double servingGrams,
) {
  try {
    const defaultServingSize = 100.0;
    final nutrients = (foodData['foodNutrients'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    print('🔍 Extracting nutrients from ${nutrients.length} items');

    double findNutrient({
  int? nutrientId,
  String? searchTerm,
}) {
  for (var n in nutrients) {
    // ✅ Handle both formats
    final id = n['nutrientId'] ?? n['nutrient']?['id'];

    final name =
        (n['nutrient']?['name'] ??
                n['nutrientName'] ??
                '')
            .toString()
            .toLowerCase();

    final value = (n['amount'] ?? n['value'] ?? 0).toDouble();

    if ((nutrientId != null && id == nutrientId) ||
        (searchTerm != null && name.contains(searchTerm.toLowerCase()))) {
      return (value / 100.0) * servingGrams;
    }
  }
  return 0.0;
}


    final carbs = findNutrient(nutrientId: 1005);
final fiber = findNutrient(nutrientId: 1079);
final protein = findNutrient(nutrientId: 1003);
final fat = findNutrient(nutrientId: 1004);
final calories = findNutrient(nutrientId: 1008);

    return {
      'carbs': carbs,
      'fiber': fiber,
      'netCarbs': (carbs - fiber).clamp(0, double.infinity),
      'protein': protein,
      'fat': fat,
      'calories': calories,
    };
  } catch (e) {
    print('❌ Error extracting nutrients: $e');
    return {
      'carbs': 0.0,
      'fiber': 0.0,
      'netCarbs': 0.0,
      'protein': 0.0,
      'fat': 0.0,
      'calories': 0.0,
    };
  }
}

  
  Future<Map<String, dynamic>> getFoodWithServing(String foodName) async {
    try {
      final results = await searchFood(foodName, limit: 1);

      if (results.isEmpty) {
        throw Exception('No foods found matching: $foodName');
      }

      final result = results.first;
      final grams = result.getStandardServingGrams();
      final description = result.getServingDescription();

      return {
        'fdcId': result.fdcId,
        'foodName': result.description,
        'description': description,
        'grams': grams,
        'servingSizes': result.servingSizes,
        'searchResult': result,
      };
    } catch (e) {
      print('❌ Error getting food with serving: $e');
      rethrow;
    }
  }


  void clearCache() {
    _searchCache.clear();
    _detailCache.clear();
    print('🧹 Caches cleared');
  }

  /// Get cache statistics (for debugging)
  Map<String, int> getCacheStats() {
    return {
      'searchCacheSize': _searchCache.length,
      'detailCacheSize': _detailCache.length,
      'totalCachedItems': _searchCache.length + _detailCache.length,
    };
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}

/// Example usage and testing
void exampleUSDAServiceUsage() async {
  // Initialize service with your API key
  final service = USDAService(apiKey: 'bRh1MNJXp3tkapV1aNrPpPcVJ4EPB8mohpSO5UBA');

  try {
    // Example 1: Simple food search
    print('📋 Example 1: Search for rice');
    final riceResults = await service.searchFood('rice', limit: 3);
    for (var result in riceResults) {
      print('  - ${result.description}');
      print('    Serving: ${result.getServingDescription()}');
      print('    Grams: ${result.getStandardServingGrams()}g');
    }

    // Example 2: Get food with serving size
    print('\n📋 Example 2: Get apple with standard serving');
    final appleData = await service.getFoodWithServing('apple');
    print('  FDC ID: ${appleData['fdcId']}');
    print('  Description: ${appleData['description']}');
    print('  Grams: ${appleData['grams']}g');

    // Example 3: Get detailed nutrition
    print('\n📋 Example 3: Get detailed nutrition for rice');
    const riceFdcId = '169897';
    final details = await service.getFoodDetails(riceFdcId);
    final nutrients = service.extractNutrients(details, 158.0); // 1 cup
    print('  Carbs: ${nutrients['carbs']}g');
    print('  Protein: ${nutrients['protein']}g');
    print('  Calories: ${nutrients['calories']}');

    // Example 4: Cache statistics
    print('\n📋 Example 4: Cache statistics');
    print(service.getCacheStats());

  } catch (e) {
    print('Error: $e');
  } finally {
    service.dispose();
  }
}
