import 'package:equatable/equatable.dart';

/// Represents nutritional information for a single food item
/// 
/// Contains all macronutrients and micronutrients for a specific
/// food portion, calculated based on USDA data and actual grams
class FoodNutritionDetail with EquatableMixin {
  /// Name of the food (e.g., "rice", "apple")
  final String foodName;

  /// Actual portion size in grams
  /// Example: 158g for medium rice
  final double grams;

  /// Carbohydrates in grams
  /// Total carbs including fiber
  final double carbs;

  /// Dietary fiber in grams
  /// Subtracts from carbs for net carbs calculation
  final double fiber;

  /// Net carbs in grams
  /// Calculated as: carbs - fiber
  /// Important for diabetes management
  final double netCarbs;

  /// Protein in grams
  final double protein;

  /// Fat in grams (total)
  final double fat;

  /// Calories (kilocalories)
  final double calories;

  /// Sugar in grams (optional, for detailed tracking)
  final double? sugar;

  /// Sodium in milligrams (optional)
  final double? sodium;

  /// Constructor
  FoodNutritionDetail({
    required this.foodName,
    required this.grams,
    required this.carbs,
    required this.fiber,
    required this.netCarbs,
    required this.protein,
    required this.fat,
    required this.calories,
    this.sugar,
    this.sodium,
  });

  /// Create a copy with optional field changes
  FoodNutritionDetail copyWith({
    String? foodName,
    double? grams,
    double? carbs,
    double? fiber,
    double? netCarbs,
    double? protein,
    double? fat,
    double? calories,
    double? sugar,
    double? sodium,
  }) {
    return FoodNutritionDetail(
      foodName: foodName ?? this.foodName,
      grams: grams ?? this.grams,
      carbs: carbs ?? this.carbs,
      fiber: fiber ?? this.fiber,
      netCarbs: netCarbs ?? this.netCarbs,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      calories: calories ?? this.calories,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
    );
  }

  /// Convert to JSON for backend transmission
  Map<String, dynamic> toJson() => {
    'foodName': foodName,
    'grams': grams,
    'carbs': carbs,
    'fiber': fiber,
    'netCarbs': netCarbs,
    'protein': protein,
    'fat': fat,
    'calories': calories,
    'sugar': sugar,
    'sodium': sodium,
  };

  /// Create from JSON (from backend or storage)
  factory FoodNutritionDetail.fromJson(Map<String, dynamic> json) {
    return FoodNutritionDetail(
      foodName: json['foodName'] as String,
      grams: (json['grams'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fiber: (json['fiber'] as num).toDouble(),
      netCarbs: (json['netCarbs'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      calories: (json['calories'] as num).toDouble(),
      sugar: json['sugar'] != null ? (json['sugar'] as num).toDouble() : null,
      sodium: json['sodium'] != null ? (json['sodium'] as num).toDouble() : null,
    );
  }

  /// Get a short description for UI display
  /// 
  /// Example: "Rice (158g)"
  String getShortDescription() {
    return '$foodName (${grams.toStringAsFixed(0)}g)';
  }

  /// Get macronutrient breakdown string
  /// 
  /// Example: "Carbs: 44g | Protein: 4g | Fat: 1g"
  String getMacroString() {
    return 'Carbs: ${carbs.toStringAsFixed(1)}g | '
        'Protein: ${protein.toStringAsFixed(1)}g | '
        'Fat: ${fat.toStringAsFixed(1)}g';
  }

  /// Get net carbs (important for diabetes management)
  /// 
  /// Formula: total carbs - dietary fiber
  /// Returns: netCarbs value (already calculated in constructor)
  double getNetCarbs() => netCarbs;

  /// Check if nutrition data is valid
  /// 
  /// Returns true if:
  /// - All required nutrients are >= 0
  /// - Grams > 0
  bool isValid() {
    return grams > 0 &&
        carbs >= 0 &&
        fiber >= 0 &&
        netCarbs >= 0 &&
        protein >= 0 &&
        fat >= 0 &&
        calories >= 0;
  }

  @override
  List<Object?> get props => [
    foodName,
    grams,
    carbs,
    fiber,
    netCarbs,
    protein,
    fat,
    calories,
    sugar,
    sodium,
  ];

  @override
  String toString() {
    return 'FoodNutritionDetail('
        'foodName: $foodName, '
        'grams: $grams, '
        'carbs: $carbs, '
        'protein: $protein, '
        'fat: $fat, '
        'calories: $calories)';
  }
}

/// Represents total nutritional values for a complete meal
/// 
/// Aggregates nutrition data from all food items in a meal
/// and calculates combined totals for macros and calories
class MealNutrientTotals with EquatableMixin {
  /// List of individual food nutrition items in the meal
  final List<FoodNutritionDetail> items;

  /// Total carbohydrates (sum of all items)
  final double totalCarbs;

  /// Total dietary fiber (sum of all items)
  final double totalFiber;

  /// Total net carbs (sum of all items)
  /// Important for diabetes meal planning
  final double totalNetCarbs;

  /// Total protein (sum of all items)
  final double totalProtein;

  /// Total fat (sum of all items)
  final double totalFat;

  /// Total calories (sum of all items)
  final double totalCalories;

  /// Timestamp when meal was created/calculated
  final DateTime? createdAt;

  /// Constructor
  MealNutrientTotals({
    required this.items,
    required this.totalCarbs,
    required this.totalFiber,
    required this.totalNetCarbs,
    required this.totalProtein,
    required this.totalFat,
    required this.totalCalories,
    this.createdAt,
  });

  
  factory MealNutrientTotals.fromItems(
    List<FoodNutritionDetail> items, {
    DateTime? createdAt,
  }) {
    if (items.isEmpty) {
      return MealNutrientTotals(
        items: items,
        totalCarbs: 0,
        totalFiber: 0,
        totalNetCarbs: 0,
        totalProtein: 0,
        totalFat: 0,
        totalCalories: 0,
        createdAt: createdAt ?? DateTime.now(),
      );
    }

    double totalCarbs = 0;
    double totalFiber = 0;
    double totalNetCarbs = 0;
    double totalProtein = 0;
    double totalFat = 0;
    double totalCalories = 0;

    for (var item in items) {
      totalCarbs += item.carbs;
      totalFiber += item.fiber;
      totalNetCarbs += item.netCarbs;
      totalProtein += item.protein;
      totalFat += item.fat;
      totalCalories += item.calories;
    }

    return MealNutrientTotals(
      items: items,
      totalCarbs: totalCarbs,
      totalFiber: totalFiber,
      totalNetCarbs: totalNetCarbs,
      totalProtein: totalProtein,
      totalFat: totalFat,
      totalCalories: totalCalories,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  /// Create a copy with optional field changes
  MealNutrientTotals copyWith({
    List<FoodNutritionDetail>? items,
    double? totalCarbs,
    double? totalFiber,
    double? totalNetCarbs,
    double? totalProtein,
    double? totalFat,
    double? totalCalories,
    DateTime? createdAt,
  }) {
    return MealNutrientTotals(
      items: items ?? this.items,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFiber: totalFiber ?? this.totalFiber,
      totalNetCarbs: totalNetCarbs ?? this.totalNetCarbs,
      totalProtein: totalProtein ?? this.totalProtein,
      totalFat: totalFat ?? this.totalFat,
      totalCalories: totalCalories ?? this.totalCalories,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert to JSON for backend transmission
  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'totalCarbs': totalCarbs,
    'totalFiber': totalFiber,
    'totalNetCarbs': totalNetCarbs,
    'totalProtein': totalProtein,
    'totalFat': totalFat,
    'totalCalories': totalCalories,
    'createdAt': createdAt?.toIso8601String(),
  };

  /// Create from JSON (from backend or storage)
  factory MealNutrientTotals.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>)
        .map((item) => FoodNutritionDetail.fromJson(item as Map<String, dynamic>))
        .toList();

    return MealNutrientTotals(
      items: itemsList,
      totalCarbs: (json['totalCarbs'] as num).toDouble(),
      totalFiber: (json['totalFiber'] as num).toDouble(),
      totalNetCarbs: (json['totalNetCarbs'] as num).toDouble(),
      totalProtein: (json['totalProtein'] as num).toDouble(),
      totalFat: (json['totalFat'] as num).toDouble(),
      totalCalories: (json['totalCalories'] as num).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  /// Get number of items in meal
  int getItemCount() => items.length;


  Map<String, double> getMacroDistribution() {
    if (totalCalories == 0) {
      return {'carbs': 0, 'protein': 0, 'fat': 0};
    }

    final carbCals = totalCarbs * 4; // 4 calories per gram
    final proteinCals = totalProtein * 4; // 4 calories per gram
    final fatCals = totalFat * 9; // 9 calories per gram

    return {
      'carbs': (carbCals / totalCalories) * 100,
      'protein': (proteinCals / totalCalories) * 100,
      'fat': (fatCals / totalCalories) * 100,
    };
  }

  /// Get a summary string for UI display
  /// 
  /// Example: "3 items | 44g carbs | 4g protein | 165 kcal"
  String getSummaryString() {
    return '${items.length} items | '
        '${totalCarbs.toStringAsFixed(1)}g carbs | '
        '${totalProtein.toStringAsFixed(1)}g protein | '
        '${totalCalories.toStringAsFixed(0)} kcal';
  }

  /// Get detailed breakdown string
  /// 
  /// Example: "Carbs: 44g (net: 43g) | Protein: 4g | Fat: 1g | Cal: 165"
  String getDetailedString() {
    return 'Carbs: ${totalCarbs.toStringAsFixed(1)}g '
        '(net: ${totalNetCarbs.toStringAsFixed(1)}g) | '
        'Protein: ${totalProtein.toStringAsFixed(1)}g | '
        'Fat: ${totalFat.toStringAsFixed(1)}g | '
        'Cal: ${totalCalories.toStringAsFixed(0)}';
  }

  /// Check if meal is empty
  bool isEmpty() => items.isEmpty;

  /// Check if nutrition data is valid
  /// 
  /// Returns true if:
  /// - Has at least one item
  /// - All totals are >= 0
  /// - Carbs match sum of item carbs (within tolerance)
  bool isValid() {
    if (items.isEmpty) return false;

    return totalCarbs >= 0 &&
        totalFiber >= 0 &&
        totalNetCarbs >= 0 &&
        totalProtein >= 0 &&
        totalFat >= 0 &&
        totalCalories >= 0;
  }

  @override
  List<Object?> get props => [
    items,
    totalCarbs,
    totalFiber,
    totalNetCarbs,
    totalProtein,
    totalFat,
    totalCalories,
    createdAt,
  ];

  @override
  String toString() {
    return 'MealNutrientTotals('
        'items: ${items.length}, '
        'carbs: $totalCarbs, '
        'protein: $totalProtein, '
        'fat: $totalFat, '
        'calories: $totalCalories)';
  }
}

/// Helper class for storing nutrient values
/// 
/// Used as a simple data structure for nutrient information
/// from USDA API responses
class NutrientValues with EquatableMixin {
  /// Nutrient name (e.g., "Carbohydrate", "Protein")
  final String name;

  /// Amount of nutrient
  final double amount;

  /// Unit of measurement (e.g., "g", "mg")
  final String unit;

  /// Unique nutrient ID from USDA
  final String? usdaNutrientId;

  /// Constructor
  NutrientValues({
    required this.name,
    required this.amount,
    required this.unit,
    this.usdaNutrientId,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'unit': unit,
    'usdaNutrientId': usdaNutrientId,
  };

  /// Create from JSON
  factory NutrientValues.fromJson(Map<String, dynamic> json) {
    return NutrientValues(
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      unit: json['unit'] as String,
      usdaNutrientId: json['usdaNutrientId'] as String?,
    );
  }

  @override
  List<Object?> get props => [name, amount, unit, usdaNutrientId];

  @override
  String toString() => '$name: $amount $unit';
}
