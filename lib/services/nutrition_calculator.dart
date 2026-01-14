
import 'package:carbcheck/model/PlateItem.dart';
import 'package:carbcheck/model/nutrition_models.dart';
import 'package:carbcheck/services/serving_calculator.dart';
import 'package:carbcheck/services/usda_service.dart';

/// Service for calculating nutrition information from foods
/// 
/// Combines USDA data, serving sizes, and portion calculations
/// to provide accurate nutrition values for meals
class NutritionCalculator {
  /// USDA Service instance for fetching food data
  final USDAService usdaService;

  /// Constructor
  NutritionCalculator({required this.usdaService});

  /// Calculate nutrition for a single food
  /// 
  /// Example:
  /// ```dart
  /// final nutrition = await calculator.calculateFoodNutrition(
  ///   foodName: 'rice',
  ///   selectedUnit: 'Medium',
  ///   quantity: 1,
  ///   standardServingGrams: 158,
  /// );
  /// // Returns FoodNutritionDetail with carbs: 44.2, etc.
  /// ```
  Future<FoodNutritionDetail> calculateFoodNutrition({
    required String foodName,
    required String selectedUnit,
    required int quantity,
    required double standardServingGrams,
    String? usdaFdcId,
  }) async {
    try {
      // Step 1: Calculate actual grams
      final grams = ServingSizeCalculator.calculateGrams(
        standardServingGrams: standardServingGrams,
        selectedUnit: selectedUnit,
        quantity: quantity,
      );

      print('📊 Calculating nutrition for: $foodName');
      print('   Portion: $selectedUnit × $quantity = ${grams}g');

      // Step 2: Get USDA data
      Map<String, double> nutrients;

      if (usdaFdcId != null && usdaFdcId.isNotEmpty) {
        // Use existing FDC ID
        print('📥 Fetching USDA data for FDC ID: $usdaFdcId');
        final details = await usdaService.getFoodDetails(usdaFdcId);
        nutrients = usdaService.extractNutrients(details, grams);
      } else {
        // Search for food
        print('🔍 Searching for: $foodName');
        final result = await usdaService.getFoodWithServing(foodName);
        final fdcId = result['fdcId'] as String;
        final details = await usdaService.getFoodDetails(fdcId);
        
        // Scale to actual portion (not standard serving)
        nutrients = usdaService.extractNutrients(details, grams);
      }

      // Step 3: Create FoodNutritionDetail
      final nutrition = FoodNutritionDetail(
        foodName: foodName,
        grams: grams,
        carbs: nutrients['carbs'] ?? 0.0,
        fiber: nutrients['fiber'] ?? 0.0,
        netCarbs: nutrients['netCarbs'] ?? 0.0,
        protein: nutrients['protein'] ?? 0.0,
        fat: nutrients['fat'] ?? 0.0,
        calories: nutrients['calories'] ?? 0.0,
      );

      print('✅ Calculated nutrition:');
      print('   ${nutrition.getMacroString()}');
      print('   Calories: ${nutrition.calories}');

      return nutrition;
    } catch (e) {
      print('❌ Error calculating nutrition: $e');
      rethrow;
    }
  }

  /// Calculate nutrition from PlateItem
  /// 
  /// Convenience method that uses PlateItem data directly
  /// 
  /// Example:
  /// ```dart
  /// final nutrition = await calculator.calculateFromPlateItem(
  ///   item: plateItem,
  ///   standardServingGrams: 158,
  /// );
  /// ```
  Future<FoodNutritionDetail> calculateFromPlateItem(
    PlateItem item, {
    required double standardServingGrams,
  }) {
    return calculateFoodNutrition(
      foodName: item.foodName,
      selectedUnit: item.selectedUnit,
      quantity: item.quantity,
      standardServingGrams: standardServingGrams,
      usdaFdcId: item.usdaFdcId,
    );
  }

  /// Calculate nutrition for multiple foods
  /// 
  /// Example:
  /// ```dart
  /// final foods = [
  ///   {'name': 'rice', 'unit': 'Medium', 'qty': 1, 'std': 158},
  ///   {'name': 'chicken', 'unit': 'Medium', 'qty': 1, 'std': 100},
  /// ];
  /// 
  /// final items = await calculator.calculateMultiple(foods);
  /// // Returns list of FoodNutritionDetail
  /// ```
  Future<List<FoodNutritionDetail>> calculateMultiple(
    List<Map<String, dynamic>> foods,
  ) async {
    final results = <FoodNutritionDetail>[];

    for (var food in foods) {
      try {
        final nutrition = await calculateFoodNutrition(
          foodName: food['name'] as String,
          selectedUnit: food['unit'] as String,
          quantity: food['qty'] as int,
          standardServingGrams: food['std'] as double,
          usdaFdcId: food['fdc'] as String?,
        );
        results.add(nutrition);
      } catch (e) {
        print('⚠️ Failed to calculate ${food['name']}: $e');
        continue;
      }
    }

    return results;
  }

  /// Calculate total meal nutrition from items
  /// 
  /// Example:
  /// ```dart
  /// final items = [
  ///   FoodNutritionDetail(...), // rice
  ///   FoodNutritionDetail(...), // chicken
  /// ];
  /// 
  /// final meal = calculator.calculateMealNutrients(items);
  /// // Returns MealNutrientTotals with combined nutrition
  /// ```
  MealNutrientTotals calculateMealNutrients(
    List<FoodNutritionDetail> items,
  ) {
    if (items.isEmpty) {
      print('⚠️ No items to calculate');
      return MealNutrientTotals.fromItems([]);
    }

    print('📊 Calculating meal totals for ${items.length} items');

    final meal = MealNutrientTotals.fromItems(items);

    print('✅ Meal totals:');
    print('   ${meal.getSummaryString()}');
    print('   Detailed: ${meal.getDetailedString()}');

    return meal;
  }

  /// Calculate nutrition for complete meal
  /// 
  /// Combines search, portion calculation, and nutrition in one call
  /// 
  /// Example:
  /// ```dart
  /// final meal = await calculator.calculateCompleteMeal([
  ///   {'name': 'rice', 'unit': 'Medium', 'qty': 1, 'std': 158},
  ///   {'name': 'chicken', 'unit': 'Large', 'qty': 1, 'std': 100},
  /// ]);
  /// ```
  Future<MealNutrientTotals> calculateCompleteMeal(
    List<Map<String, dynamic>> foods,
  ) async {
    try {
      // Step 1: Calculate nutrition for each food
      final items = await calculateMultiple(foods);

      // Step 2: Combine into meal
      final meal = calculateMealNutrients(items);

      return meal;
    } catch (e) {
      print('❌ Error calculating complete meal: $e');
      rethrow;
    }
  }

  /// Compare nutrition between two portion sizes
  /// 
  /// Example:
  /// ```dart
  /// final comparison = await calculator.comparePortion(
  ///   foodName: 'apple',
  ///   standardServingGrams: 182,
  ///   portion1: 'Small',
  ///   portion2: 'Large',
  /// );
  /// // Returns {'Small': FoodNutritionDetail, 'Large': FoodNutritionDetail}
  /// ```
  Future<Map<String, FoodNutritionDetail>> comparePortion(
    String foodName, {
    required double standardServingGrams,
    required String portion1,
    required String portion2,
  }) async {
    try {
      print('📊 Comparing $portion1 vs $portion2 for $foodName');

      final nutrition1 = await calculateFoodNutrition(
        foodName: foodName,
        selectedUnit: portion1,
        quantity: 1,
        standardServingGrams: standardServingGrams,
      );

      final nutrition2 = await calculateFoodNutrition(
        foodName: foodName,
        selectedUnit: portion2,
        quantity: 1,
        standardServingGrams: standardServingGrams,
      );

      print('✅ Comparison:');
      print('   $portion1: ${nutrition1.getMacroString()}');
      print('   $portion2: ${nutrition2.getMacroString()}');

      return {
        portion1: nutrition1,
        portion2: nutrition2,
      };
    } catch (e) {
      print('❌ Error comparing portions: $e');
      rethrow;
    }
  }

  /// Get nutrition for all portion sizes
  /// 
  /// Example:
  /// ```dart
  /// final options = await calculator.getPortionOptions(
  ///   foodName: 'apple',
  ///   standardServingGrams: 182,
  /// );
  /// // Returns {'Small': {...}, 'Medium': {...}, 'Large': {...}}
  /// ```
  Future<Map<String, FoodNutritionDetail>> getPortionOptions(
    String foodName, {
    required double standardServingGrams,
  }) async {
    try {
      final options = <String, FoodNutritionDetail>{};

      for (var portion in ServingSizeCalculator.getValidPortions()) {
        final nutrition = await calculateFoodNutrition(
          foodName: foodName,
          selectedUnit: portion,
          quantity: 1,
          standardServingGrams: standardServingGrams,
        );
        options[portion] = nutrition;
      }

      return options;
    } catch (e) {
      print('❌ Error getting portion options: $e');
      rethrow;
    }
  }

  /// Validate nutrition calculation
  /// 
  /// Returns null if valid, error message if invalid
  static String? validateNutrition(FoodNutritionDetail nutrition) {
    if (nutrition.grams <= 0) {
      return 'Grams must be greater than 0';
    }
    if (nutrition.carbs < 0 ||
        nutrition.protein < 0 ||
        nutrition.fat < 0 ||
        nutrition.calories < 0) {
      return 'Nutrients cannot be negative';
    }
    if (nutrition.netCarbs < 0) {
      return 'Net carbs cannot be negative';
    }
    if (nutrition.fiber > nutrition.carbs) {
      return 'Fiber cannot exceed carbs';
    }
    return null;
  }

  /// Get nutrition adjustment factor
  /// 
  /// Used to scale nutrition from one portion to another
  /// 
  /// Example:
  /// ```dart
  /// final factor = NutritionCalculator.getAdjustmentFactor(
  ///   currentGrams: 158,
  ///   targetGrams: 200,
  /// );
  /// // Returns 1.266 (multiply current nutrition by this)
  /// ```
  static double getAdjustmentFactor({
    required double currentGrams,
    required double targetGrams,
  }) {
    if (currentGrams == 0) return 1.0;
    return targetGrams / currentGrams;
  }

  /// Scale nutrition to different portion
  /// 
  /// Example:
  /// ```dart
  /// final scaled = NutritionCalculator.scaleNutrition(
  ///   nutrition: original,
  ///   newGrams: 200,
  /// );
  /// ```
  static FoodNutritionDetail scaleNutrition(
    FoodNutritionDetail nutrition, {
    required double newGrams,
  }) {
    final factor = getAdjustmentFactor(
      currentGrams: nutrition.grams,
      targetGrams: newGrams,
    );

    return nutrition.copyWith(
      grams: newGrams,
      carbs: nutrition.carbs * factor,
      fiber: nutrition.fiber * factor,
      netCarbs: nutrition.netCarbs * factor,
      protein: nutrition.protein * factor,
      fat: nutrition.fat * factor,
      calories: nutrition.calories * factor,
    );
  }

  /// Calculate macro distribution percentages
  /// 
  /// Example:
  /// ```dart
  /// final distribution = NutritionCalculator.getMacroDistribution(
  ///   carbs: 44.2,
  ///   protein: 4.3,
  ///   fat: 0.3,
  /// );
  /// // Returns {'carbs': 78.8, 'protein': 7.7, 'fat': 0.5}
  /// ```
  static Map<String, double> getMacroDistribution({
    required double carbs,
    required double protein,
    required double fat,
  }) {
    final carbCals = carbs * 4;      // 4 cal per gram
    final proteinCals = protein * 4; // 4 cal per gram
    final fatCals = fat * 9;         // 9 cal per gram

    final total = carbCals + proteinCals + fatCals;

    if (total == 0) {
      return {'carbs': 0, 'protein': 0, 'fat': 0};
    }

    return {
      'carbs': (carbCals / total) * 100,
      'protein': (proteinCals / total) * 100,
      'fat': (fatCals / total) * 100,
    };
  }

  /// Estimate calories from macronutrients
  /// 
  /// Example:
  /// ```dart
  /// final calories = NutritionCalculator.estimateCalories(
  ///   carbs: 44.2,
  ///   protein: 4.3,
  ///   fat: 0.3,
  /// );
  /// // Returns approximately 206
  /// ```
  static double estimateCalories({
    required double carbs,
    required double protein,
    required double fat,
  }) {
    return (carbs * 4) + (protein * 4) + (fat * 9);
  }

  /// Get nutrition per 100g
  /// 
  /// Useful for comparing foods on standard basis
  static FoodNutritionDetail normalizeTo100g(
    FoodNutritionDetail nutrition,
  ) {
    final factor = 100 / nutrition.grams;

    return nutrition.copyWith(
      grams: 100,
      carbs: nutrition.carbs * factor,
      fiber: nutrition.fiber * factor,
      netCarbs: nutrition.netCarbs * factor,
      protein: nutrition.protein * factor,
      fat: nutrition.fat * factor,
      calories: nutrition.calories * factor,
    );
  }
}

/// Batch nutrition calculator for processing multiple meals
class BatchNutritionCalculator {
  final NutritionCalculator calculator;

  /// Constructor
  BatchNutritionCalculator({required this.calculator});

  /// Calculate nutrition for multiple meals
  /// 
  /// Example:
  /// ```dart
  /// final meals = [
  ///   [
  ///     {'name': 'rice', 'unit': 'Medium', 'qty': 1, 'std': 158},
  ///     {'name': 'chicken', 'unit': 'Medium', 'qty': 1, 'std': 100},
  ///   ],
  ///   [
  ///     {'name': 'apple', 'unit': 'Large', 'qty': 1, 'std': 182},
  ///   ],
  /// ];
  /// 
  /// final results = await batch.calculateMeals(meals);
  /// // Returns list of MealNutrientTotals
  /// ```
  Future<List<MealNutrientTotals>> calculateMeals(
    List<List<Map<String, dynamic>>> meals,
  ) async {
    final results = <MealNutrientTotals>[];

    for (var i = 0; i < meals.length; i++) {
      try {
        print('📊 Calculating meal ${i + 1}/${meals.length}');
        final meal = await calculator.calculateCompleteMeal(meals[i]);
        results.add(meal);
      } catch (e) {
        print('⚠️ Failed to calculate meal ${i + 1}: $e');
        continue;
      }
    }

    return results;
  }

  /// Calculate daily nutrition totals
  /// 
  /// Sums nutrition across all meals
  Future<MealNutrientTotals> calculateDailyTotals(
    List<List<Map<String, dynamic>>> meals,
  ) async {
    final mealResults = await calculateMeals(meals);

    if (mealResults.isEmpty) {
      return MealNutrientTotals.fromItems([]);
    }

    // Combine all items from all meals
    final allItems = <FoodNutritionDetail>[];
    for (var meal in mealResults) {
      allItems.addAll(meal.items);
    }

    return MealNutrientTotals.fromItems(allItems);
  }
}
